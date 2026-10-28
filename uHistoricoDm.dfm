object dmHistorico: TdmHistorico
  OnCreate = DataModuleCreate
  Height = 240
  Width = 320
  object qryExecucoes: TFDQuery
    SQL.Strings = (
      'select E.ID, E.ID_PERFIL, P.NOME as PERFIL, E.VERSAO_PERFIL, P.VERSAO as VERSAO_ATUAL,'
      '  E.INICIO, E.FIM, E.STATUS,'
      '  case E.STATUS'
      '    when '#39'EM_ANDAMENTO'#39' then '#39'Em andamento'#39
      '    when '#39'CONCLUIDA'#39' then '#39'Conclu'#237'da'#39
      '    when '#39'CONCLUIDA_COM_ERROS'#39' then '#39'Conclu'#237'da com erros'#39
      '    when '#39'INTERROMPIDA'#39' then '#39'Interrompida por erro'#39
      '    when '#39'CANCELADA'#39' then '#39'Cancelada pelo usu'#225'rio'#39
      '    when '#39'DESFEITA'#39' then '#39'Desfeita (nada gravado)'#39
      '    when '#39'FALHOU'#39' then '#39'Falhou'#39
      '    else E.STATUS'
      '  end as SITUACAO,'
      '  E.ESTRATEGIA, E.ACAO_ERRO, E.LINHAS_LIDAS, E.INSERIDAS, E.ATUALIZADAS, E.IGNORADAS,'
      '  E.VALIDADAS, E.COM_ERRO, E.VAZIAS, E.LINHA_INICIO, E.ULTIMA_LINHA, E.ID_EXECUCAO_ORIGEM,'
      '  coalesce((select max(R.ID) from EXECUCAO R where R.ID_EXECUCAO_ORIGEM = E.ID), 0) as RETOMADA_POR,'
      '  E.ARQUIVO, E.ABA, E.CONEXAO, E.TABELA_DESTINO, E.MENSAGEM'
      'from EXECUCAO E'
      'join PERFIL P on P.ID = E.ID_PERFIL'
      'where (:ID_PERFIL = 0 or E.ID_PERFIL = :ID_PERFIL)'
      'order by E.ID desc')
    Left = 48
    Top = 24
    ParamData = <
      item
        Name = 'ID_PERFIL'
        DataType = ftInteger
        ParamType = ptInput
      end>
  end
  object dsExecucoes: TDataSource
    DataSet = qryExecucoes
    Left = 144
    Top = 24
  end
  object qryErros: TFDQuery
    SQL.Strings = (
      'select LINHA, CAMPO,'
      '  case TIPO_ERRO'
      '    when '#39'VALIDACAO'#39' then '#39'Valida'#231#227'o'#39
      '    when '#39'TRANSFORMACAO'#39' then '#39'Transforma'#231#227'o'#39
      '    when '#39'REFERENCIA'#39' then '#39'Refer'#234'ncia'#39
      '    when '#39'GRAVACAO'#39' then '#39'Grava'#231#227'o'#39
      '    else TIPO_ERRO'
      '  end as TIPO,'
      '  VALOR_RECEBIDO, MENSAGEM'
      'from EXECUCAO_ERRO'
      'where ID_EXECUCAO = :ID_EXECUCAO'
      'order by ID')
    Left = 48
    Top = 96
    ParamData = <
      item
        Name = 'ID_EXECUCAO'
        DataType = ftInteger
        ParamType = ptInput
      end>
  end
  object dsErros: TDataSource
    DataSet = qryErros
    Left = 144
    Top = 96
  end
end
