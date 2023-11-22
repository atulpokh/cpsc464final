//atul@cs.yale.edu
/* Common definitions */

typedef struct household *hhPointer;

typedef struct household
{
	int hhid;
	int familysize;
	int income;
	int race;
	int ethnicity;
	int u18;
	int o65;
	int vet;
	int disability;
	int waittime;
	int choice; // which preference matched. 0 is unmatched.
	int whenjoined;
	int whenleft;
	int pref1;
	int pref2;
	int pref3;
	int pref4;
    int huid;
} hhtype;

typedef struct hunit *huPointer;

typedef struct hunit {
	int huid;
	int capacity;
	int vacant;
	int development;
} hunittype;

