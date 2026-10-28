object frmPrincipal: TfrmPrincipal
  Left = 0
  Top = 0
  Caption = 'Bless Import'
  ClientHeight = 600
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  WindowState = wsMaximized
  OnCreate = FormCreate
  TextHeight = 15
  object nbMenu: TdxNavBar
    Left = 0
    Top = 0
    Width = 220
    Height = 581
    Align = alLeft
    ActiveGroupIndex = 0
    ShowLinksHint = True
    View = 18
    object nbgCadastros: TdxNavBarGroup
      Caption = 'Cadastros'
      SelectedLinkIndex = -1
      TopVisibleLinkIndex = 0
      Links = <
        item
          Item = nbiConexoes
        end
        item
          Item = nbiPerfis
        end>
    end
    object nbgImportacao: TdxNavBarGroup
      Caption = 'Importa'#231#227'o'
      SelectedLinkIndex = -1
      TopVisibleLinkIndex = 0
      Links = <
        item
          Item = nbiImportarPlanilha
        end
        item
          Item = nbiHistorico
        end>
    end
    object nbgFerramentas: TdxNavBarGroup
      Caption = 'Ferramentas'
      SelectedLinkIndex = -1
      TopVisibleLinkIndex = 0
      Links = <
        item
          Item = nbiVisualizarPlanilha
        end
        item
          Item = nbiMetadadosDestino
        end>
    end
    object nbgSistema: TdxNavBarGroup
      Caption = 'Sistema'
      SelectedLinkIndex = -1
      TopVisibleLinkIndex = 0
      Links = <
        item
          Item = nbiSair
        end>
    end
    object nbiConexoes: TdxNavBarItem
      Caption = 'Conex'#245'es'
      Hint = 'Bancos de destino (ERPs)'
      OnClick = mnuConexoesClick
    end
    object nbiPerfis: TdxNavBarItem
      Caption = 'Perfis de importa'#231#227'o'
      Hint = 'Mapeamento da planilha para a tabela do ERP'
      OnClick = mnuPerfisClick
    end
    object nbiImportarPlanilha: TdxNavBarItem
      Caption = 'Importar planilha'
      Hint = 'Validar, pr'#233'-visualizar e gravar'
      OnClick = mnuImportarPlanilhaClick
    end
    object nbiHistorico: TdxNavBarItem
      Caption = 'Hist'#243'rico de importa'#231#245'es'
      Hint = 'Execu'#231#245'es, erros e retomada de importa'#231#245'es interrompidas'
      OnClick = mnuHistoricoClick
    end
    object nbiVisualizarPlanilha: TdxNavBarItem
      Caption = 'Visualizar planilha'
      Hint = 'Abrir uma planilha e ver colunas e tipos'
      OnClick = mnuVisualizarPlanilhaClick
    end
    object nbiMetadadosDestino: TdxNavBarItem
      Caption = 'Metadados do destino'
      Hint = 'Tabelas, campos e generators do banco de destino'
      OnClick = mnuMetadadosDestinoClick
    end
    object nbiSair: TdxNavBarItem
      Caption = 'Sair'
      Hint = 'Fechar o programa'
      OnClick = mnuSairClick
    end
  end
  object pcJanelas: TPageControl
    Left = 220
    Top = 0
    Width = 780
    Height = 581
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    OwnerDraw = True
    ParentFont = False
    TabOrder = 1
    OnDrawTab = pcJanelasDrawTab
  end
  object sbStatus: TStatusBar
    Left = 0
    Top = 581
    Width = 1000
    Height = 19
    Panels = <>
    SimplePanel = True
  end
end
