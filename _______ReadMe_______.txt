****************************************************************************************************************************************************
DESCRIPTION:
***************************************************************************************************************************************************
The dbg() proc captures run-time info and logs it in a table. Comes in handy when debugging in the normal way is hard or impossible.
For example, if the proc gets non-obvious parameters, it's easier and more reliable to perform the user scenario, and then read the captured info.
If the proc reads data from another package, the regular debugging is impossible at all if that data is populated by other parts of the app.

***************************************************************************************************************************************************
FEATURES:
***************************************************************************************************************************************************
* Extracts the calling package & subprogram names from the call stack and writes them to the debug log, so you don't need to pass them.
* Cleans up after the previous debug session to eliminate a buildup of old log records. You always see only the results of the last debug session.
* Uses an autonomous transaction so you can debug exceptions (otherwise, the debug records would be rolled back).
* Can be called from any PL/SQL code including PL/SQL blocks within SQL scripts and Oracle Reports RDF files.

***************************************************************************************************************************************************
ATTENTION!!!
***************************************************************************************************************************************************
Before creating the proc, run this:
CREATE TABLE dbg_log (id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, pkg VARCHAR2(128), proc VARCHAR2(128),
   msg VARCHAR2(4000), developer VARCHAR2(100) NOT NULL, wen DATE NOT NULL);
   
***************************************************************************************************************************************************
EXAMPLES OF USE:
***************************************************************************************************************************************************
Save the following examples in a file and change "larryellison" to your personal marker.
Each time you need to debug, copy-paste the needed line and customize:

dbg('CALLED', 'larryellison'); -- add at the beginning of the subprogram to check if it's called
dbg(DBMS_UTILITY.FORMAT_CALL_STACK, 'larryellison'); -- see the whole call stack of the subprogram
dbg('<<1>>', 'larryellison'); -- add to a code block (like IF...) to check if the program flow entered it ('<<1>>', '<<2>>' etc. for different blocks)

* Debug variables:
dbg('v1=' || v1, 'larryellison');
dbg('v1=' || v1 || ', v2=' || v2, 'larryellison');
dbg('v1=' || v1 || ', v2=' || v2 || ', v3=' || v3, 'larryellison');
dbg('v1=' || v1 || ', v2=' || v2 || ', v3=' || v3 || ', v4=' || v4, 'larryellison');
dbg('v1=' || v1 || ', v2=' || v2 || ', v3=' || v3 || ', v4=' || v4 || ', v5=' || v5, 'larryellison');
dbg('v1=' || v1 || ', v2=' || v2 || ', v3=' || v3 || ', v4=' || v4 || ', v5=' || v5 || ', v6=' || v6, 'larryellison');
dbg('v1=' || v1 || ', v2=' || v2 || ', v3=' || v3 || ', v4=' || v4 || ', v5=' || v5 || ', v6=' || v6 || ', v7=' || v7, 'larryellison');

* Debug SQL commands:
dbg('UPDATE xxx updated ' || SQL%ROWCOUNT || ' rows', 'larryellison');
dbg('DELETE FROM xxx deleted ' || SQL%ROWCOUNT || ' rows', 'larryellison');
dbg('INSERT INTO xxx inserted ' || SQL%ROWCOUNT || ' rows', 'larryellison');
dbg('cur_XXX fetched ' || cur_XXX%ROWCOUNT || ' rows', 'larryellison'); -- after the FETCH but before CLOSE cur_XXX!

* Debug a CLOB containing a string longer than 4000 characters (call a separate dbg for every 4000 characters):
dbg(DBMS_LOB.SUBSTR(i_xml, 4000, 1), 'larryellison');
dbg(DBMS_LOB.SUBSTR(i_xml, 4000, 4001), 'larryellison');
dbg(DBMS_LOB.SUBSTR(i_xml, 4000, 8001), 'larryellison');
Then put all the pieces togeter in a text file.
If you capture an unformatted or all-in-one-line XML or SQL, use these sites to nicely format it:
XML: https://freeformatter.com/xml-formatter.html
SQL: https://sqlformat.org/

***************************************************************************************************************************************************
EXAMPLES OF USE IN SQL SCRIPTS:
***************************************************************************************************************************************************
* Debug script variables (those accessed with &&):
dbg('v1=&&v1', 'larryellison');
dbg('v1=&&v1, v2=&&v2', 'larryellison');
dbg('v1=&&v1, v2=&&v2, v3=&&v3', 'larryellison');
dbg('v1=&&v1, v2=&&v2, v3=&&v3, v4=&&v4', 'larryellison');

* If you need to call dbg() out of existing BEGIN...END blocks, ornament it with its own block:
BEGIN dbg('<MSG>', 'larryellison'); END;
/

* SQL%ROWCOUNT exists only in PL/SQL, so you can capture it only for SQLs within BEGIN...END blocks.

* Some scripts are running for longer than 30 seconds. Debug them this way:
1. Add at the beginning (since i_delete_old is not passed, this call will clean up after your previous debug session):
BEGIN dbg('CALLED', 'larryellison'); END;
/
2. In ALL (!!!) subsequent calls, pass i_delete_old = FALSE:
dbg('<MSG>', 'larryellison', FALSE);

3. If you want to make sure that the script has been executed in whole, add at the end:
BEGIN dbg('DONE', 'larryellison', FALSE); END;
/

***************************************************************************************************************************************************
SKIPPING LOGGING:
***************************************************************************************************************************************************
The i_log_when parameter allows you to pass a Boolean expression to log only on specific circumstances.
If the expression evaluates to FALSE, the logging is skipped.
Example: dbg() is called in a loop for thousands of Orders, but you want to debug only one Order:
dbg('<MSG>', 'larryellison', i_log_when => (rec.order_id = 12345));

***************************************************************************************************************************************************
READ THE CREATED LOG:
***************************************************************************************************************************************************
SELECT pkg || '.' || proc AS proc, msg, TO_CHAR(wen, 'DD-MON-YYYY hh:mi:ss') AS wen
  FROM dbg_log
 WHERE developer = Lower('larryellison')
 ORDER BY id;

***************************************************************************************************************************************************
@@@ If you have called dbg() from many packages, then, before committing your work, find and remove all the dbg() calls:
***************************************************************************************************************************************************
SELECT name, type, line, text
  FROM user_source
 WHERE text LIKE '%dbg(%'
   AND text LIKE Lower('%larryellison%')
   AND name <> 'DBG'
 ORDER BY name, line;