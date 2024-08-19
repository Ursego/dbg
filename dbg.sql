CREATE OR REPLACE PROCEDURE dbg (
  i_msg        IN dbg_log.msg%TYPE,
  i_developer  IN dbg_log.developer%TYPE, -- your personal marker, like 'larryellison' for Larry Ellison (must be unique in your organization)
  i_delete_old IN BOOLEAN := TRUE,        -- delete log records older than 30 seconds
  i_log_when   IN BOOLEAN := TRUE         -- pass a Boolean expression defining when to log
)
/***************************************************************************************************************************************************
Purpose: Debugging Oracle PL/SQL code without debugger
****************************************************************************************************************************************************
Description & examples of use: https://github.com/Ursego/dbg/blob/main/_______ReadMe_______.txt
****************************************************************************************************************************************************
Developer: https://www.linkedin.com/in/zuskin/
***************************************************************************************************************************************************/
IS
  v_pkg                dbg_log.pkg%TYPE;
  v_proc               dbg_log.proc%TYPE;
  c_msg       CONSTANT dbg_log.msg%TYPE       := SUBSTR(i_msg, 1, 4000);
  c_developer CONSTANT dbg_log.developer%TYPE := Lower(i_developer);
  c_now       CONSTANT dbg_log.wen%TYPE       := SYSDATE;
  
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  IF NOT i_log_when THEN RETURN; END IF;

  BEGIN
    IF utl_call_stack.subprogram(2).count > 1 THEN -- called from a packaged procedure/function
      v_pkg  := utl_call_stack.subprogram(2)(1);
      v_proc := utl_call_stack.subprogram(2)(2);
    ELSE -- called from a standalone procedure/function, SQL script or PL/SQL editor
      v_pkg  := '---';
      v_proc := utl_call_stack.subprogram(2)(1);
      IF v_proc = '__anonymous_block' THEN -- called from a SQL script or PL/SQL editor
        v_proc := 'ANONYMOUS BLOCK';
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      -- When dbg() is called from an RDF, utl_call_stack.subprogram has only 1 element,
      -- and accessing utl_call_stack.subprogram(2) gives "ORA-64610: bad depth indicator".
      -- That is a very rare situation. So, to improve performance, catch that exception
      -- rather than check "IF utl_call_stack.dynamic_depth < 2" on each call.
      v_pkg  := '---';
      v_proc := '---';
  END;
  
  IF i_delete_old THEN
    DELETE FROM dbg_log
     WHERE developer = c_developer
       AND wen       < (c_now - (30/86400)); -- older than 30 seconds
  END IF;

  INSERT INTO dbg_log (pkg, proc, msg, developer, wen) VALUES (v_pkg, v_proc, c_msg, c_developer, c_now);
  COMMIT;
END dbg;
