inherited frmPerfisImportar: TfrmPerfisImportar
  Caption = 'Importar perfis'
  ClientHeight = 470
  ClientWidth = 720
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  inherited pnlRodape: TPanel
    Top = 423
    Width = 708
    TabOrder = 4
    DesignSize = (
      708
      41)
    inherited btnFechar: TButton
      Left = 625
      Caption = 'Cancelar'
      TabOrder = 1
    end
    object btnImportar: TButton
      Left = 539
      Top = 8
      Width = 80
      Height = 27
      Anchors = [akTop, akRight]
      Caption = 'Importar'
      Default = True
      TabOrder = 0
      OnClick = btnImportarClick
    end
  end
  object lblArquivo: TLabel
    Left = 16
    Top = 12
    Width = 688
    Height = 15
    AutoSize = False
    Caption = 'Arquivo:'
    EllipsisPosition = epPathEllipsis
  end
  object lblPerfis: TLabel
    Left = 16
    Top = 38
    Width = 220
    Height = 15
    Caption = 'Perfis do arquivo (marque os que vai importar):'
  end
  object clbPerfis: TCheckListBox
    Left = 16
    Top = 58
    Width = 688
    Height = 230
    ItemHeight = 17
    TabOrder = 0
  end
  object lblConexao: TLabel
    Left = 16
    Top = 300
    Width = 280
    Height = 15
    Caption = 'Conex'#227'o de destino dos perfis (neste banco):'
  end
  object cbxConexao: TComboBox
    Left = 16
    Top = 320
    Width = 400
    Height = 23
    Style = csDropDownList
    TabOrder = 1
  end
  object rgExistente: TRadioGroup
    Left = 16
    Top = 354
    Width = 688
    Height = 60
    Caption = ' Se j'#225' existir um perfil com o mesmo nome '
    Columns = 3
    ItemIndex = 1
    Items.Strings = (
      'Substituir (mant'#233'm o ID e sobe a vers'#227'o)'
      'Criar uma c'#243'pia'
      'Pular')
    TabOrder = 2
  end
end
