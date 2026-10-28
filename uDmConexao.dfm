object dmConexao: TdmConexao
  OnCreate = DataModuleCreate
  Height = 240
  Width = 320
  object cnConexao: TFDConnection
    Params.Strings = (
      'DriverID=FB'
      'Protocol=TCPIP'
      'Server=localhost'
      'Port=3050'
      'Database=BLESS_IMPORT'
      'User_Name=SYSDBA'
      'Password=pmpsyfwr'
      'SQLDialect=3'
      'CharacterSet=UTF8')
    LoginPrompt = False
    Transaction = trTransacao
    UpdateTransaction = trTransacao
    BeforeConnect = cnConexaoBeforeConnect
    Left = 48
    Top = 24
  end
  object trTransacao: TFDTransaction
    Options.Isolation = xiReadCommitted
    Options.AutoStop = False
    Connection = cnConexao
    Left = 144
    Top = 24
  end
  object linkDriver: TFDPhysFBDriverLink
    Left = 48
    Top = 96
  end
end
