inherited frmPerfis: TfrmPerfis
  Caption = 'Perfis de importa'#231#227'o'
  ClientHeight = 450
  ClientWidth = 1000
  OnCreate = FormCreate
  TextHeight = 15
  inherited pnlRodape: TPanel
    Top = 403
    Width = 988
    DesignSize = (
      988
      41)
    inherited btnFechar: TButton
      Left = 905
    end
  end
  object pnlBotoes: TPanel
    Left = 6
    Top = 6
    Width = 988
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object btnNovo: TButton
      Left = 0
      Top = 6
      Width = 90
      Height = 27
      Caption = 'Novo'
      TabOrder = 0
      OnClick = btnNovoClick
    end
    object btnEditar: TButton
      Left = 96
      Top = 6
      Width = 90
      Height = 27
      Caption = 'Editar'
      TabOrder = 1
      OnClick = btnEditarClick
    end
    object btnDuplicar: TButton
      Left = 192
      Top = 6
      Width = 90
      Height = 27
      Caption = 'Duplicar'
      TabOrder = 2
      OnClick = btnDuplicarClick
    end
    object btnExcluir: TButton
      Left = 288
      Top = 6
      Width = 90
      Height = 27
      Caption = 'Excluir'
      TabOrder = 3
      OnClick = btnExcluirClick
    end
  end
  object grdPerfis: TDBGrid
    Left = 6
    Top = 47
    Width = 988
    Height = 356
    Align = alClient
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
    ReadOnly = True
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
    OnDblClick = grdPerfisDblClick
    Columns = <
      item
        Expanded = False
        FieldName = 'NOME'
        Title.Caption = 'Nome'
        Width = 200
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CONEXAO'
        Title.Caption = 'Conex'#227'o'
        Width = 140
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ERP'
        Width = 70
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'TABELA_DESTINO'
        Title.Caption = 'Tabela de destino'
        Width = 150
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CAMPOS_MAPEADOS'
        Title.Caption = 'Campos mapeados'
        Width = 110
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'VERSAO'
        Title.Caption = 'Vers'#227'o'
        Width = 50
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'DATA_ALTERACAO'
        Title.Caption = 'Alterado em'
        Width = 130
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ARQUIVO_EXEMPLO'
        Title.Caption = 'Planilha de exemplo'
        Width = 300
        Visible = True
      end>
  end
end
