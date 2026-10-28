inherited frmConexaoEdicao: TfrmConexaoEdicao
  Caption = 'Conex'#227'o'
  ClientHeight = 366
  ClientWidth = 470
  TextHeight = 15
  inherited pnlRodape: TPanel
    Top = 319
    Width = 458
    TabOrder = 9
    DesignSize = (
      458
      41)
    inherited btnFechar: TButton
      Left = 375
      Caption = 'Cancelar'
      TabOrder = 2
    end
    object btnGravar: TButton
      Left = 289
      Top = 8
      Width = 80
      Height = 27
      Anchors = [akTop, akRight]
      Caption = 'Gravar'
      Default = True
      TabOrder = 1
      OnClick = btnGravarClick
    end
    object btnTestar: TButton
      Left = 0
      Top = 8
      Width = 120
      Height = 27
      Caption = 'Testar conex'#227'o'
      TabOrder = 0
      OnClick = btnTestarClick
    end
  end
  object lblNome: TLabel
    Left = 16
    Top = 19
    Width = 36
    Height = 15
    Caption = 'Nome:'
  end
  object edtNome: TEdit
    Left = 120
    Top = 16
    Width = 330
    Height = 23
    MaxLength = 60
    TabOrder = 0
  end
  object lblErp: TLabel
    Left = 16
    Top = 51
    Width = 24
    Height = 15
    Caption = 'ERP:'
  end
  object cbxErp: TComboBox
    Left = 120
    Top = 48
    Width = 150
    Height = 23
    Style = csDropDownList
    TabOrder = 1
    Items.Strings = (
      'SIDI'
      'FINANCE'
      'INJET')
  end
  object lblServidor: TLabel
    Left = 16
    Top = 83
    Width = 46
    Height = 15
    Caption = 'Servidor:'
  end
  object edtServidor: TEdit
    Left = 120
    Top = 80
    Width = 200
    Height = 23
    MaxLength = 100
    TabOrder = 2
  end
  object lblPorta: TLabel
    Left = 16
    Top = 115
    Width = 31
    Height = 15
    Caption = 'Porta:'
  end
  object edtPorta: TEdit
    Left = 120
    Top = 112
    Width = 80
    Height = 23
    NumbersOnly = True
    TabOrder = 3
  end
  object lblBanco: TLabel
    Left = 16
    Top = 147
    Width = 36
    Height = 15
    Caption = 'Banco:'
  end
  object edtBanco: TEdit
    Left = 120
    Top = 144
    Width = 330
    Height = 23
    Hint = 'Alias do Firebird (ex.: SIDI) ou caminho do arquivo .FDB no servidor'
    MaxLength = 255
    ParentShowHint = False
    ShowHint = True
    TabOrder = 4
  end
  object lblUsuario: TLabel
    Left = 16
    Top = 179
    Width = 43
    Height = 15
    Caption = 'Usu'#225'rio:'
  end
  object edtUsuario: TEdit
    Left = 120
    Top = 176
    Width = 150
    Height = 23
    MaxLength = 60
    TabOrder = 5
  end
  object lblSenha: TLabel
    Left = 16
    Top = 211
    Width = 35
    Height = 15
    Caption = 'Senha:'
  end
  object edtSenha: TEdit
    Left = 120
    Top = 208
    Width = 150
    Height = 23
    PasswordChar = '*'
    TabOrder = 6
  end
  object lblCharset: TLabel
    Left = 16
    Top = 243
    Width = 44
    Height = 15
    Caption = 'Charset:'
  end
  object cbxCharset: TComboBox
    Left = 120
    Top = 240
    Width = 150
    Height = 23
    TabOrder = 7
    Items.Strings = (
      'WIN1252'
      'UTF8'
      'ISO8859_1'
      'NONE')
  end
  object lblDialeto: TLabel
    Left = 16
    Top = 275
    Width = 41
    Height = 15
    Caption = 'Dialeto:'
  end
  object cbxDialeto: TComboBox
    Left = 120
    Top = 272
    Width = 80
    Height = 23
    Style = csDropDownList
    TabOrder = 8
    Items.Strings = (
      '1'
      '3')
  end
end
