inherited frmMetadadosDestino: TfrmMetadadosDestino
  Caption = 'Metadados do destino'
  ClientHeight = 600
  ClientWidth = 1100
  OnCreate = FormCreate
  TextHeight = 15
  inherited pnlRodape: TPanel
    Top = 553
    Width = 1088
    DesignSize = (
      1088
      41)
    inherited btnFechar: TButton
      Left = 1005
    end
  end
  object pnlTopo: TPanel
    Left = 6
    Top = 6
    Width = 1088
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object lblConexao: TLabel
      Left = 0
      Top = 12
      Width = 51
      Height = 15
      Caption = 'Conex'#227'o:'
    end
    object lblStatus: TLabel
      Left = 424
      Top = 12
      Width = 81
      Height = 15
      Caption = 'N'#227'o conectado'
    end
    object cbxConexao: TComboBox
      Left = 60
      Top = 9
      Width = 250
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnDropDown = cbxConexaoDropDown
    end
    object btnConectar: TButton
      Left = 320
      Top = 7
      Width = 90
      Height = 27
      Caption = 'Conectar'
      TabOrder = 1
      OnClick = btnConectarClick
    end
  end
  object pnlEsquerda: TPanel
    Left = 6
    Top = 47
    Width = 260
    Height = 506
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 2
    object lblTabelas: TLabel
      Left = 0
      Top = 0
      Width = 260
      Height = 15
      Align = alTop
      Caption = 'Tabelas:'
    end
    object edtFiltro: TEdit
      Left = 0
      Top = 15
      Width = 260
      Height = 23
      Align = alTop
      CharCase = ecUpperCase
      TabOrder = 0
      TextHint = 'Filtrar tabelas...'
      OnChange = edtFiltroChange
    end
    object lstTabelas: TListBox
      Left = 0
      Top = 38
      Width = 260
      Height = 268
      Align = alClient
      ItemHeight = 15
      TabOrder = 1
      OnClick = lstTabelasClick
    end
    object pnlGenerators: TPanel
      Left = 0
      Top = 306
      Width = 260
      Height = 200
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      object lblGenerators: TLabel
        Left = 0
        Top = 0
        Width = 260
        Height = 15
        Align = alTop
        Caption = 'Generators:'
      end
      object lstGenerators: TListBox
        Left = 0
        Top = 15
        Width = 260
        Height = 185
        Align = alClient
        ItemHeight = 15
        TabOrder = 0
      end
    end
  end
  object splEsquerda: TSplitter
    Left = 266
    Top = 47
    Height = 506
  end
  object pnlCampos: TPanel
    Left = 269
    Top = 47
    Width = 825
    Height = 506
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 3
    object lblResumo: TLabel
      Left = 0
      Top = 0
      Width = 825
      Height = 15
      Align = alTop
    end
    object grdCampos: TStringGrid
      Left = 0
      Top = 15
      Width = 825
      Height = 491
      Align = alClient
      ColCount = 9
      DefaultRowHeight = 22
      FixedCols = 0
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect]
      TabOrder = 0
      ColWidths = (
        40
        180
        130
        80
        80
        50
        100
        180
        70)
    end
  end
end
