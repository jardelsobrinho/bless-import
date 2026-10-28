inherited frmVisualizarPlanilha: TfrmVisualizarPlanilha
  Caption = 'Visualizar planilha'
  ClientHeight = 560
  ClientWidth = 1100
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  inherited pnlRodape: TPanel
    Top = 513
    Width = 1088
    DesignSize = (
      1088
      41)
    inherited btnFechar: TButton
      Left = 1005
    end
  end
  object pnlFiltros: TPanel
    Left = 6
    Top = 6
    Width = 1088
    Height = 97
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object lblArquivo: TLabel
      Left = 152
      Top = 12
      Width = 3
      Height = 15
    end
    object lblAba: TLabel
      Left = 0
      Top = 44
      Width = 24
      Height = 15
      Caption = 'Aba:'
    end
    object lblLinhaCabecalho: TLabel
      Left = 248
      Top = 44
      Width = 108
      Height = 15
      Caption = 'Linha do cabe'#231'alho:'
    end
    object lblLinhaInicial: TLabel
      Left = 456
      Top = 44
      Width = 125
      Height = 15
      Caption = 'Linha inicial dos dados:'
    end
    object lblResumo: TLabel
      Left = 0
      Top = 76
      Width = 3
      Height = 15
    end
    object btnAbrir: TButton
      Left = 0
      Top = 6
      Width = 140
      Height = 27
      Caption = 'Abrir planilha...'
      TabOrder = 0
      OnClick = btnAbrirClick
    end
    object cbxAba: TComboBox
      Left = 32
      Top = 41
      Width = 200
      Height = 23
      Style = csDropDownList
      TabOrder = 1
      OnChange = cbxAbaChange
    end
    object edtLinhaCabecalho: TEdit
      Left = 362
      Top = 41
      Width = 50
      Height = 23
      NumbersOnly = True
      TabOrder = 2
      Text = '1'
    end
    object udLinhaCabecalho: TUpDown
      Left = 412
      Top = 41
      Width = 16
      Height = 23
      Associate = edtLinhaCabecalho
      Max = 1000
      Position = 1
      TabOrder = 3
    end
    object edtLinhaInicial: TEdit
      Left = 587
      Top = 41
      Width = 50
      Height = 23
      NumbersOnly = True
      TabOrder = 4
      Text = '2'
    end
    object udLinhaInicial: TUpDown
      Left = 637
      Top = 41
      Width = 16
      Height = 23
      Associate = edtLinhaInicial
      Min = 1
      Max = 1000
      Position = 2
      TabOrder = 5
    end
    object btnAtualizar: TButton
      Left = 672
      Top = 39
      Width = 90
      Height = 27
      Caption = 'Atualizar'
      TabOrder = 6
      OnClick = btnAtualizarClick
    end
  end
  object grdColunas: TStringGrid
    Left = 6
    Top = 103
    Width = 420
    Height = 410
    Align = alLeft
    ColCount = 4
    DefaultColWidth = 60
    DefaultRowHeight = 22
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect]
    TabOrder = 2
    ColWidths = (
      40
      150
      70
      140)
  end
  object splColunas: TSplitter
    Left = 426
    Top = 103
    Height = 410
  end
  object grdDados: TStringGrid
    Left = 429
    Top = 103
    Width = 665
    Height = 410
    Align = alClient
    ColCount = 2
    DefaultColWidth = 120
    DefaultRowHeight = 22
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing]
    TabOrder = 3
    ColWidths = (
      50
      120)
  end
  object dlgAbrir: TOpenDialog
    Filter = 'Planilhas do Excel (*.xls;*.xlsx)|*.xls;*.xlsx|Todos os arquivos (*.*)|*.*'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Title = 'Abrir planilha'
    Left = 960
    Top = 16
  end
end
