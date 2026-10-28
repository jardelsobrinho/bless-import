/* BlessImport - banco de configurações (BLESS_IMPORT, dialeto 3)
   004 - retomada de importações interrompidas

   Executar:
   "C:\Program Files (x86)\Firebird\Firebird_4_0\isql.exe" -q -user SYSDBA -password pmpsyfwr localhost:BLESS_IMPORT -i "004 - retomada.sql"
*/

SET SQL DIALECT 3;

/* Execução que esta continua (retomada) e a linha da planilha onde ela começou */
ALTER TABLE EXECUCAO ADD ID_EXECUCAO_ORIGEM INTEGER;
ALTER TABLE EXECUCAO ADD LINHA_INICIO INTEGER DEFAULT 0 NOT NULL;
COMMIT;

ALTER TABLE EXECUCAO ADD CONSTRAINT FK_EXECUCAO_ORIGEM FOREIGN KEY (ID_EXECUCAO_ORIGEM)
  REFERENCES EXECUCAO (ID) ON DELETE SET NULL;
COMMIT;
