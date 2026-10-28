/* BlessImport - banco de configurações (BLESS_IMPORT, dialeto 3)
   005 - origem "Consulta SQL (manual)": SELECT escrito no perfil, com {Coluna} da planilha como parâmetro

   Executar:
   "C:\Program Files (x86)\Firebird\Firebird_4_0\isql.exe" -q -user SYSDBA -password pmpsyfwr localhost:BLESS_IMPORT -i "005 - consulta sql.sql"
*/

SET SQL DIALECT 3;

ALTER TABLE PERFIL_CAMPO ADD CONSULTA_SQL BLOB SUB_TYPE TEXT;
COMMIT;

/* Nova origem CONSULTA_SQL */
ALTER TABLE PERFIL_CAMPO DROP CONSTRAINT CK_PERFIL_CAMPO_ORIGEM;
COMMIT;
ALTER TABLE PERFIL_CAMPO ADD CONSTRAINT CK_PERFIL_CAMPO_ORIGEM
  CHECK (ORIGEM IN ('COLUNA', 'FIXO', 'PADRAO', 'CONSULTA', 'GERADO', 'EXPRESSAO', 'CONSULTA_SQL'));
COMMIT;
