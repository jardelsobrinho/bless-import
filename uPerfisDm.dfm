object dmPerfis: TdmPerfis
  OnCreate = DataModuleCreate
  Height = 240
  Width = 320
  object qryPerfis: TFDQuery
    SQL.Strings = (
      'select P.ID, P.NOME, C.NOME as CONEXAO, C.ERP, P.TABELA_DESTINO, P.ARQUIVO_EXEMPLO,'
      '  P.VERSAO, P.DATA_ALTERACAO,'
      '  (select count(*) from PERFIL_CAMPO PC where PC.ID_PERFIL = P.ID) as CAMPOS_MAPEADOS'
      'from PERFIL P'
      'join CONEXAO C on C.ID = P.ID_CONEXAO'
      'order by P.NOME')
    Left = 48
    Top = 24
  end
  object dsPerfis: TDataSource
    DataSet = qryPerfis
    Left = 144
    Top = 24
  end
end
