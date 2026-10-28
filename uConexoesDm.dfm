object dmConexoes: TdmConexoes
  OnCreate = DataModuleCreate
  Height = 240
  Width = 320
  object qryConexoes: TFDQuery
    SQL.Strings = (
      'select ID, NOME, ERP, SERVIDOR, PORTA, BANCO, USUARIO, CHARSET, DIALETO'
      'from CONEXAO'
      'order by NOME')
    Left = 48
    Top = 24
  end
  object dsConexoes: TDataSource
    DataSet = qryConexoes
    Left = 144
    Top = 24
  end
end
