CC = clang 
objects = match.o sqlite3.o

match : $(objects)
	$(CC) -L/opt/homebrew/lib $(objects) -lgsl -lgslcblas -lm -lpthread -o match

match.o : match.c defs.h
	$(CC) match.c defs.h -c
sqlite3.o : sqlite3.c
	$(CC) sqlite3.c -I/opt/homebrew/include -c
gsltest : gsltest.o
	$(CC) -L/opt/homebrew/lib gsltest.o -lgsl -lgslcblas -lm -o gsltest
gsltest.o :
	$(CC) gsltest.c -I/opt/homebrew/include -c
sqltest : sqltest.o sqlite3.o
	$(CC) -L/opt/homebrew/lib sqltest.o sqlite3.o -lm -lpthread -o sqltest
sqltest.o :
	$(CC) sqltest.c -c
all: match sqltest gsltest

.PHONY : clean
clean : 
	-rm -f *.o match sqltest gsltest 
