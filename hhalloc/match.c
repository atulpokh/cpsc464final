// atul@cs.yale.edu

/* Simple matching without:
 *  - waitlist volatility
 *  - occupant volatility
 *  - priority matching
 */

/* To set seed and ring type use this:
 * GSL_RNG_SEED=123 GSL_RNG_TYPE=mrg ./match
 */

// better to save output ot csv and use favorite stats package

/* sqlite backend */
/* linked list waitlist */

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <sqlite3.h>
#include <string.h>
#include <sys/queue.h>
#include <limits.h>
#include "defs.h"

#define TOTAL_EXPERIMENTS 1000 // total number of experiments
#define TOTAL_ROUNDS 1		// total number of time periods in each experiment
#define DBFILE "hhalloc.sqlite"
#define MAX_QUERY_LEN 500
#define MAX_PREF 4 // maximum number of preferences that hh have

sqlite3 *db;
int hhmatch;		// preference matching housing unit returned by sql query
int queryResultInt; // generic holder for int return values from queries
int curRound = 0;

// Waitlit is a doubly linked tail queue
struct entry
{
	hhPointer data;
	TAILQ_ENTRY(entry)
	entries; /* Tail queue */
};

TAILQ_HEAD(tailhead, entry);
struct tailhead head; /* Tail queue head */

int handle_error(int rc, char *zErrMsg)
{
	if (rc != SQLITE_OK)
	{
		fprintf(stderr, "SQL Error: %s\n", zErrMsg);
		sqlite3_free(db);
	}
	return 0;
}

// initialize waitlist
int initWaitlist()
{
	TAILQ_INIT(&head); /* Initialize the queue */
	return 0;
}

int destroyWatlist()
{
	struct entry *n1, *n2;
	n1 = TAILQ_FIRST(&head);
	while (n1 != NULL)
	{
		n2 = TAILQ_NEXT(n1, entries);
		free(n1);
		n1 = n2;
	}
	TAILQ_INIT(&head);
	return 0;
}
// Callback function sent to sqlite for adding to waitlist
// Called once per row returned
static int waitlistAdd(void *NotUsed, int argc, char **argv, char **azColName)
{
	int i;
	struct entry *n1;
	n1 = malloc(sizeof(struct entry)); /* Insert at the head */
	n1->data = malloc(sizeof(hhtype));
	// fill in struct
	// add to waitlist
	// assume fields are returned in order
	if (argc < 15)
	{
		fprintf(stderr, "Needed 15 fields to add household, got %d", argc);
		return (1);
	}
	n1->data->hhid = atoi(argv[0]);
	n1->data->familysize = atoi(argv[1]);
	n1->data->income = atoi(argv[2]);
	n1->data->race = atoi(argv[3]);
	n1->data->ethnicity = atoi(argv[4]);
	n1->data->u18 = atoi(argv[5]);
	n1->data->o65 = atoi(argv[6]);
	n1->data->vet = atoi(argv[7]);
	n1->data->disability = atoi(argv[8]);
	n1->data->waittime = atoi(argv[9]);
	n1->data->choice = atoi(argv[10]);
	n1->data->whenjoined = atoi(argv[11]);
	n1->data->whenleft = atoi(argv[12]);
	n1->data->pref1 = atoi(argv[13]);
	n1->data->pref2 = atoi(argv[14]);
	n1->data->pref3 = atoi(argv[15]);
	n1->data->pref4 = atoi(argv[16]);
	n1->data->huid = atoi(argv[17]);
	//	fprintf(stderr,"Added hhid=%d to waitlist\n", n1->data->hhid);
	TAILQ_INSERT_HEAD(&head, n1, entries);
	return 0;
}

// generic functions to capture int result of query
static int getResultInt(void *NotUsed, int argc, char **argv, char **azColName)
{
	queryResultInt = (argv[0] != NULL ? atoi(argv[0]) : -1);
	return 0;
}

// add housing unit to hhmatch
// this function is used to capture the result of queries
static int huAdd(void *NotUsed, int argc, char **argv, char **azColName)
{
	// if no match, hhmatch is -1
	hhmatch = (argv[0] != NULL ? atoi(argv[0]) : -1);
	return 0;
}

/* Allocation methods go from 0 to 3. See final project notes.*/
int assignh(int method)
{
	int i, j;
	struct entry *np;
	int prefs[MAX_PREF];
	int matched;
	int curpref;

	int rc;
	char *zErrMsg;
	char *query;

	// random assignment without priority
	if (method == 0)
	{
		TAILQ_FOREACH(np, &head, entries)
		{
			i = np->data->hhid;
			//			printf("hhid %d prefers %d capacity housing\n",i, np->data->pref1);
			// NOTE: Update this to read in all preferencs when MAX_PREF changes
			prefs[0] = np->data->pref1;
			prefs[1] = np->data->pref2;
			prefs[2] = np->data->pref3;
			prefs[3] = np->data->pref4;
			curpref = 0;
			matched = 0;
			hhmatch = 0;
			while (!matched && curpref < MAX_PREF)
			{
				// request one unit that matches preference
				query = calloc(MAX_QUERY_LEN, sizeof(char));
				snprintf(query, sizeof(query) * MAX_QUERY_LEN, "SELECT * from hu WHERE vacant = 1 AND capacity = %d LIMIT 1", prefs[curpref]);
				// printf("Query is: %s\n", query);
				rc = sqlite3_exec(db, query, huAdd, 0, &zErrMsg);
				handle_error(rc, zErrMsg);
				free(query);
				// if housing matched, update db
				if (hhmatch > 0)
				{
					matched = 1;
					// record which preference matched
					np->data->choice = curpref + 1;
					// record matching huid
					np->data->huid = hhmatch;
					// printf("Matched hh %d with unit %d (preference %d)\n", np->data->hhid, np->data->huid, np->data->choice);
					// if this is made multithreaded
					// the following needs to be a transaction to avoid database inconsistency
					// set vacancy status of housing unit to 1
					// set allocation to huid, update choice and waittime
					rc = sqlite3_exec(db, "BEGIN TRANSACTION", NULL, 0, &zErrMsg);
					handle_error(rc, zErrMsg);
					query = calloc(MAX_QUERY_LEN, sizeof(char));
					snprintf(query, sizeof(query) * MAX_QUERY_LEN,
							 "UPDATE hu SET vacant=0 WHERE huid=%d;\
							 UPDATE match SET huid=%d, choice=%d, waittime=%d  WHERE hhid=%d",
							 np->data->huid, np->data->huid, np->data->choice, curRound + 1, np->data->hhid);
					rc = sqlite3_exec(db, query, huAdd, 0, &zErrMsg);
					handle_error(rc, zErrMsg);
					free(query);
					// remove household from waitlist
					rc = sqlite3_exec(db, "END TRANSACTION", NULL, 0, &zErrMsg);
					handle_error(rc, zErrMsg);
				}
				curpref++;
			}
			// if (!matched) {printf("No match found\n");}
		}
		int numVacant = -1;
		int numUnmatched = -1;
		rc = sqlite3_exec(db, "SELECT count(hhid) FROM match WHERE huid=0", getResultInt, 0, &zErrMsg);
		handle_error(rc, zErrMsg);
		numUnmatched = queryResultInt;
		rc = sqlite3_exec(db, "SELECT count(huid) FROM hu WHERE vacant=1", getResultInt, 0, &zErrMsg);
		handle_error(rc, zErrMsg);
		numVacant = queryResultInt;
		//		printf("Match complete. Vacant: %d, Waitlist: %d \n",numVacant, numUnmatched);
		return 0;
	}

	fprintf(stderr, "Asisgnment method %d not implemented\n", method);
	return 1;
}

// vacate units

int vacate_units()
{
	// every round, remove x% of the people from apartments
	return 0;
}

// print output headers
void printheaders()
{
	for (int i = 0; i < 8; i++)
	{
		printf("numInGroup%d,", i);
		printf("matchedPct%d,", i);
		printf("avgWaitTime%d,", i);
		printf("topChoicePct%d,", i);
	}
	printf("Fairness\n");
}

// probably better to use a statistical package rather than duplicate their functions
// but recreating basic ones here
//
int printmetrics()
{
	// Metric 1 : Probability of top choice for each racial group
	int rc;
	char *zErrMsg;
	int *topChoiceNum;	// number that received their top choice in group
	int *totalWaitTime; // total wait time for group
	int *matchedTotal;	// number of group that was matched
	int *numInGroup;	// number of people in the group
	float fairness;

	int totalRaces;
	// get total number of races
	rc = sqlite3_exec(db, "SELECT COUNT(DISTINCT race) FROM hh",
					  getResultInt, 0, &zErrMsg);
	handle_error(rc, zErrMsg);
	totalRaces = queryResultInt;

	// allocate space to store results by race
	topChoiceNum = (int *)malloc(sizeof(int) * totalRaces);
	totalWaitTime = (int *)malloc(sizeof(int) * totalRaces);
	matchedTotal = (int *)malloc(sizeof(int) * totalRaces);
	numInGroup = (int *)malloc(sizeof(int) * totalRaces);

	for (int i = 0; i < totalRaces; i++)
	{
		char query[MAX_QUERY_LEN + 1];

		// total number in each group
		sprintf(query, "SELECT COUNT(hhid) FROM hh WHERE race =%d", i + 1);
		rc = sqlite3_exec(db, query, getResultInt, 0, &zErrMsg);
		handle_error(rc, zErrMsg);
		numInGroup[i] = queryResultInt;
		//printf("numIngroup %d = %d\n",i+1, numInGroup[i]);
		// number of each group that was matched
		sprintf(query, "SELECT COUNT(choice) AS totalMatched FROM hh \
LEFT JOIN match ON hh.hhid=match.hhid WHERE choice>0 AND race =%d",
				i + 1);
		rc = sqlite3_exec(db, query, getResultInt, 0, &zErrMsg);
		handle_error(rc, zErrMsg);
		matchedTotal[i] = queryResultInt;
		
		//printf("matchedIngroup %d = %d\n",i+1, matchedTotal[i]);
		// total wait time
		sprintf(query, "SELECT SUM(waittime) AS totalWaitTime FROM hh \
LEFT JOIN match ON hh.hhid=match.hhid WHERE choice>0 AND race =%d",
				i + 1);
		rc = sqlite3_exec(db, query, getResultInt, 0, &zErrMsg);
		handle_error(rc, zErrMsg);
		totalWaitTime[i] = queryResultInt;
		// printf("waittime for group %d = %d\n",i+1, totalWaitTime[i]);

		// number that got their first choice
		sprintf(query, "SELECT COUNT(choice) AS firstChoiceNum FROM hh \
LEFT JOIN match ON hh.hhid=match.hhid WHERE choice=1 AND race =%d",
				i + 1);
		rc = sqlite3_exec(db, query, getResultInt, 0, &zErrMsg);
		handle_error(rc, zErrMsg);
		topChoiceNum[i] = queryResultInt;
		// printf("topChoiceNum for group %d = %d\n",i+1, topChoiceNum[i]);
	}

	for (int i = 0; i < totalRaces; i++)
	{
		printf("%d,",numInGroup[i]);
		// Metric 1: Percentage in each group that was matched
		printf("%3.5f,", (matchedTotal[i]*1.0/ numInGroup[i]) * 100.0);
		// Metric 2: Percentage in each group that got first choice
		printf("%3.5f,", (topChoiceNum[i]*1.0/ matchedTotal[i]) * 100.0);
		// Metric 3 : Average wait time for each racial group
		printf("%3.5f,", (totalWaitTime[i]*1.0 / matchedTotal[i]) * 1.0);
	}
	// Metric 4 : Fairness (see writeup for details)
	// 1 - sum_over_all_groups_j (sum_over_all_groups_i (pct_first_choice_group_i/pct_first_choice_group_j))
	float innerSum = 0.0;
	for (int i = 0; i < totalRaces; i++)
	{
		for (int j = 0; j < totalRaces; j++)
		{
			if (j == i)
			{
				continue;
			}
			innerSum += (topChoiceNum[i] / matchedTotal[i]) / (topChoiceNum[j] / matchedTotal[j]);
		}
	}
	fairness = 1.0 - innerSum;
	printf("%3.5f\n", fairness);

	free(topChoiceNum);
	free(totalWaitTime);
	free(matchedTotal);
	free(numInGroup);
	
	return 0;
}

int main()
{
	int experimentNo;
	for (experimentNo = 0; experimentNo < TOTAL_EXPERIMENTS; experimentNo++)
	{
	int rc, i;
	char *zErrMsg;
		// print output headers and open database once
		if (experimentNo == 0)
		{
			printheaders();
			rc = sqlite3_open(DBFILE, &db);
			if (rc)
			{
				fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(db));
				sqlite3_close(db);
				return (1);
			}
		}
		// Step 0: Reset Database for experiment
		// set all units to be vacant
		rc = sqlite3_exec(db, "UPDATE hu set vacant = 1", NULL, 0, &zErrMsg);
		handle_error(rc, zErrMsg);
		// set all households to be unassigned
		// reset choice received
		// reset waittime
		rc = sqlite3_exec(db, "UPDATE match set huid = 0, choice = 0, waittime = 0 ", NULL, 0, &zErrMsg);
		handle_error(rc, zErrMsg);

		// print out some initial stats
		int numVacant = -1;
		int numUnmatched = -1;
		rc = sqlite3_exec(db, "SELECT count(hhid) FROM match WHERE huid=0", getResultInt, 0, &zErrMsg);
		handle_error(rc, zErrMsg);
		numUnmatched = queryResultInt;
		rc = sqlite3_exec(db, "SELECT count(huid) FROM hu WHERE vacant=1", getResultInt, 0, &zErrMsg);
		handle_error(rc, zErrMsg);
		numVacant = queryResultInt;
		// printf("Match commencing. Vacant: %d, Waitlist: %d \n", numVacant, numUnmatched);
		//  Step 1:  add households to the waitlist randomly
		//  Initialize waitlist
		initWaitlist();
		// populate from database
		char *query;
		query = (char *)calloc(MAX_QUERY_LEN + 1, sizeof(char));
		strlcat(query, "SELECT * from hh LEFT JOIN match ON hh.hhid = match.hhid ORDER BY RANDOM()", MAX_QUERY_LEN);
		//printf("waitlist query: %s", query);
		rc = sqlite3_exec(db, query, waitlistAdd, 0, &zErrMsg);
		free(query);
		handle_error(rc, zErrMsg);
	
		// Step 2: assign available units to households using specified method

		for (curRound = 0; curRound < TOTAL_ROUNDS; curRound++)
		{
			assignh(0);
			// households can vacate
			//	vacate_units();
			// waitlisters can vacate
			//	vacate_waitlist());
			// new people can be added to waitlist
			// printmetrics();
		}

		// Step 3: Calculate fairness metrics once per experiment
		printmetrics();
		destroyWatlist();
		// clean up
		if (experimentNo >= TOTAL_EXPERIMENTS - 1)
		{
			sqlite3_close(db);
		}
	}
	return 0;
}
