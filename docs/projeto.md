# Projeto: Importador Universal de Dados para ERPs — Delphi 11

## 1. Contexto do projeto

Trabalho em uma empresa de software que possui vários sistemas ERP, incluindo SIDI, FINANCE e INJET.

Quando um novo cliente começa a utilizar nossos sistemas, preciso importar os dados do sistema anterior desse cliente para um ou mais dos nossos ERPs.

Os dados de origem são fornecidos em planilhas Excel (.xls), que podem variar de estrutura, nomes de colunas, posição do cabeçalho, quantidade de abas e tipos de dados.

Quero desenvolver uma aplicação desktop em Delphi 11 para Windows que funcione como um importador universal, configurável e extensível.

O objetivo é evitar desenvolver uma rotina específica para cada cliente. Quero configurar o mapeamento dos dados, salvar essas configurações e reutilizá-las em outras importações.

O sistema deverá permitir personalizações sem exigir alterações constantes no código-fonte principal.

## 2. Princípios arquiteturais

Antes de implementar, analise os requisitos, identifique possíveis conflitos e proponha uma arquitetura que atenda aos seguintes princípios:

- Separar a interface gráfica, as regras de importação, a leitura das planilhas e o acesso aos bancos de dados.
- Utilizar interfaces e classes desacopladas, facilitando a inclusão de novos bancos de dados e ERPs.
- Não assumir que todos os bancos utilizam o mesmo componente de acesso a dados.
- Não limitar a solução a uma única planilha ou a uma única tabela.
- Permitir que uma importação envolva várias tabelas relacionadas.
- Salvar todas as configurações necessárias para reproduzir uma importação.
- Evitar regras de negócio fixas no código quando elas puderem ser configuradas.
- Permitir implementar regras personalizadas quando a configuração genérica não for suficiente.
- Não criar uma arquitetura excessivamente complexa sem necessidade.

Utilize recursos compatíveis com Delphi 11. Não utilize recursos exclusivos de versões posteriores do Delphi.

Existe um projeto em F:\Work\bless-marketplace, utilize uma arquitetura parecida com a dele. Criando datamoudles, usando firedac para conexão com o banco, usando o padrão para nomes dos arquivos, etc.

O banco de dados que vai salvar as configurações do aplicativo se chama BLESS_DATA_IMPORT.FDB e deve está na pasta F:\Work\bless-dataimport\bin\data, seu aliases é BLESS_DATA_IMPORT, usuario SYSDBA, senha pmpsyfwr. Crie um arquivo .ini para configurar esse acesso.

## 3. Conexões e seleção dos dados

A aplicação deverá permitir:

1. Cadastrar e selecionar conexões com os bancos de dados de destino.
2. Trabalhar com diferentes bancos de dados, utilizando adaptadores específicos quando necessário.
3. Consultar metadados do banco, incluindo tabelas, campos, tipos de dados, tamanhos, campos obrigatórios, chaves primárias e relacionamentos, quando disponíveis.
4. Selecionar a tabela de destino.
5. Selecionar o arquivo de planilha (.xls) de origem.
6. Selecionar a aba da planilha que contém os registros.
7. Analisar a estrutura da aba e apresentar suas colunas, exemplos de valores e possíveis tipos de dados.
8. Permitir indicar a linha de cabeçalho e a linha onde começam os dados, e ignorar linhas que não representam registros (títulos, totais, linhas em branco).

Não presuma que todas as planilhas possuem a mesma estrutura. Cada cliente pode fornecer planilhas com nomes de colunas, ordem, cabeçalhos e formatos diferentes, e uma planilha pode conter clientes, produtos, itens ou lançamentos financeiros.

## 4. Mapeamento dos campos e origem dos valores

Crie uma interface visual para associar as colunas da planilha aos campos da tabela de destino.

A tela deverá apresentar:

- Campo de destino no ERP.
- Coluna de origem na planilha.
- Aba e posição da coluna na planilha.
- Exemplo do valor encontrado no arquivo.
- Tipo de dado de origem.
- Tipo de dado de destino.
- Origem do valor.
- Transformação configurada.
- Valor fixo ou padrão, quando aplicável.
- Indicação de campo obrigatório.
- Regra personalizada, quando aplicável.

### 4.1. Seleção da origem do valor

Para cada campo da tabela de destino, o usuário deverá poder escolher como o valor será obtido.

Implemente inicialmente as seguintes opções:

**1. Coluna da planilha**

Obtém o valor de uma coluna selecionada na planilha.

**2. Valor fixo**

Utiliza um valor definido pelo usuário em todos os registros importados naquela configuração, independentemente do conteúdo da planilha.

Exemplos:
- `COD_EMPRESA = 1`
- `ATIVO = 'S'`
- `ORIGEM = 'IMPORTACAO'`

O valor deverá respeitar o tipo de dado do campo de destino.

**3. Valor padrão**

Utiliza um valor configurado quando o valor de origem estiver ausente, vazio ou nulo, conforme as condições definidas pelo usuário.

Exemplo: a planilha não possui a coluna `ATIVO`. O usuário configura o valor padrão `S`, que será utilizado quando não houver valor válido de origem.

Permita definir em quais situações o padrão será aplicado:

- Coluna inexistente.
- Valor vazio.
- Valor nulo.
- Valor inválido ou incompatível, quando explicitamente configurado.

O sistema não deverá substituir silenciosamente valores inválidos por padrões sem que esse comportamento esteja configurado.

**4. Campo personalizado**

Obtém o valor por meio de uma regra específica implementada para atender às necessidades de determinado ERP ou cliente.

**5. Consulta ao banco de dados**

Busca um valor em uma tabela do banco de destino ou em outra fonte configurada, utilizando critérios de pesquisa definidos pelo usuário.

**6. Valor gerado**

Obtém um valor gerado pelo banco de dados ou pelo ERP, como uma chave primária ou um código interno. O sistema deverá respeitar a estratégia de geração utilizada pelo destino.

**7. Expressão ou transformação**

Obtém o valor a partir de um ou mais campos, utilizando operações como concatenação, cálculos, condições ou conversões.

### 4.2. Regras de precedência

Diferencie claramente as opções:

- Valor fixo: sempre utiliza o valor configurado.
- Valor padrão: utiliza o valor configurado somente quando a condição definida for atendida.
- Coluna da planilha: utiliza o valor de origem, aplicando as transformações configuradas.
- Consulta ou regra personalizada: obtém o valor conforme a regra definida.

Não implemente uma precedência implícita que possa gerar resultados inesperados. A configuração deverá deixar claro como valores de origem, transformações, padrões e validações serão combinados.

### 4.3. Interface de configuração

A interface deverá possuir uma coluna chamada `Origem do valor`.

Ao selecionar uma opção, o sistema deverá exibir os controles necessários para configurá-la.

Exemplos:

- Ao selecionar `Coluna da planilha`, exibir a lista de colunas da aba selecionada, com exemplos de valores.
- Ao selecionar `Valor fixo`, exibir um campo para digitação do valor.
- Ao selecionar `Valor padrão`, exibir o valor padrão e as condições de aplicação.
- Ao selecionar `Consulta ao banco`, exibir os parâmetros da consulta.
- Ao selecionar `Campo personalizado`, permitir selecionar uma regra registrada na aplicação.

O usuário deverá conseguir mapear uma coluna da planilha para um campo do banco e, quando necessário, utilizar o mesmo campo de origem em mais de uma regra de destino.

Deve existir validação para identificar campos obrigatórios sem mapeamento, valores incompatíveis e configurações inválidas.

## 5. Tratamento e transformação de dados

O sistema deverá possuir um mecanismo extensível de transformação de dados.

Implemente, inicialmente, suporte para:

- Texto para data.
- Texto para data e hora.
- Texto para número inteiro.
- Texto para números decimais e monetários.
- Conversão de valores booleanos.
- Tratamento de valores nulos e vazios.
- Remoção de espaços.
- Normalização de CPF e CNPJ.
- Definição de valores fixos e padrões.
- Concatenação de campos.
- Conversões de maiúsculas e minúsculas.
- Arredondamento numérico configurável.
- Expressões condicionais simples.

As conversões devem considerar formatos brasileiros, como datas e valores decimais, sem depender indevidamente das configurações regionais da máquina.

Cada transformação deverá validar o resultado e gerar uma mensagem clara quando não for possível converter o valor.

Não faça conversões silenciosas que possam alterar incorretamente valores financeiros, datas ou identificadores.

O mecanismo deverá permitir adicionar novas transformações sem modificar o processamento central da importação.

As transformações deverão ser compatíveis com todas as origens de valor para as quais fizerem sentido, inclusive valores fixos, valores padrão e resultados de consultas.

## 6. Personalização das regras

O sistema deverá permitir personalizações em três níveis:

1. Regras genéricas disponíveis para qualquer importação.
2. Regras específicas de um perfil de importação.
3. Regras personalizadas implementadas por desenvolvedores, quando necessárias.

Permita configurar valores fixos, valores padrão, condições, cálculos, pesquisas no banco e transformações específicas.

Para regras personalizadas, proponha uma estratégia baseada em interfaces, classes ou provedores de regras registrados na aplicação.

Não permita que uma planilha execute código arbitrário. Fórmulas e macros não devem ser executadas; apenas os valores das células devem ser lidos.

Não torne a solução dependente de scripts externos ou de compilação de código para realizar operações simples que poderiam ser configuradas pela interface.

## 7. Dependências e ordem de importação

A importação deverá ser de 1 tabela por vez.

## 8. Resolução de referências e códigos internos

Este é um requisito fundamental.

As planilhas podem utilizar identificadores diferentes dos utilizados pelo ERP.

Por exemplo, na planilha de origem, um cliente é identificado pelo CNPJ. No ERP de destino, o cliente possui um código interno numérico.

Ao importar um lançamento financeiro, a planilha contém o CNPJ do cliente, mas a tabela financeira exige o código interno do cliente.

O sistema deverá permitir configurar uma regra de resolução de referência que:

1. Leia o identificador disponível na planilha ou em outra origem configurada.
2. Consulte a tabela de destino utilizando a chave de negócio configurada, como CNPJ, CPF ou código externo.
3. Recupere o identificador interno do ERP.
4. Utilize esse identificador no campo correspondente do registro dependente.
5. Registre uma pendência quando não encontrar o registro relacionado.

Essa funcionalidade deverá funcionar tanto para registros recém-importados quanto para registros que já existiam no ERP.

Permita configurar:

- Tabela de consulta.
- Campo utilizado na pesquisa.
- Valor de origem da pesquisa.
- Condições adicionais, quando necessárias.
- Campo interno que deverá ser recuperado.
- Campo de destino que receberá o valor recuperado.
- Comportamento quando o registro não for encontrado.

A origem do identificador deverá poder ser uma coluna da planilha, um valor fixo, uma transformação ou outra regra compatível.

Não assuma que toda referência será resolvida por CNPJ. A chave de pesquisa deverá ser configurável.

Quando um registro for inserido durante a própria importação, o sistema deverá capturar sua chave gerada ou consultar novamente o registro, conforme a estratégia suportada pelo banco.

Evite consultas desnecessárias para cada linha. Considere mecanismos de cache e resolução em lote, desde que preservem a consistência dos dados.

## 9. Estratégia de gravação

Cada tabela ou etapa deverá permitir configurar o comportamento de gravação:

- Inserir registros novos.
- Atualizar registros existentes.
- Inserir ou atualizar, conforme uma chave de identificação.
- Ignorar registros já existentes.
- Validar sem gravar.

A identificação de registros existentes deverá utilizar chaves configuráveis, como código externo, CPF, CNPJ ou combinação de campos.

O sistema deverá considerar as chaves primárias geradas pelo banco e os relacionamentos existentes.

Utilize consultas parametrizadas para valores de origem. Não concatene valores da planilha diretamente em comandos SQL.

Os nomes de tabelas e campos deverão ser validados a partir dos metadados e das configurações permitidas.

Não assuma que todos os bancos aceitam a mesma sintaxe SQL ou suportam os mesmos recursos transacionais.

Quando ocorrer um erro, permita configurar se a importação deverá interromper a etapa, continuar com os próximos registros independentes ou cancelar todo o processo.

A estratégia transacional deverá considerar as limitações do banco e as dependências entre as etapas. Não prometa rollback global quando a operação envolver transações independentes ou bancos que não participam da mesma transação distribuída.

## 10. Persistência das configurações

O sistema deverá salvar os perfis de importação para reutilização futura.

Um perfil deverá conter, quando aplicável:

- Nome e descrição.
- ERP de destino.
- Identificação da conexão ou referência à conexão.
- Estrutura da planilha: aba, linha de cabeçalho, linha inicial dos dados e colunas.
- Mapeamento dos campos.
- Origem configurada para cada valor.
- Valores fixos.
- Valores padrão e suas condições de aplicação.
- Transformações.
- Regras de resolução de referências.
- Estratégia de gravação.
- Dependências entre etapas.
- Validações.
- Regras personalizadas registradas.
- Versão da configuração.

Separe as credenciais das configurações reutilizáveis. Não armazene senhas em texto puro.

Permita duplicar, editar, versionar e reutilizar perfis.

Antes de executar um perfil salvo, valide se as tabelas, os campos e as colunas da planilha ainda são compatíveis com a configuração.

## 11. Execução, validação e monitoramento

Antes de gravar, o sistema deverá permitir visualizar os dados transformados e os valores que serão enviados ao banco.

Implemente:

- Validação prévia sem gravação.
- Pré-visualização dos registros.
- Exibição do valor final de cada campo.
- Exibição da origem de cada valor: planilha, fixo, padrão, consulta ou regra personalizada.
- Contagem de registros de origem.
- Contagem de registros processados.
- Quantidade de inserções, atualizações e registros ignorados.
- Registro dos erros por etapa e por registro.
- Identificação do campo que causou o erro.
- Mensagem clara com o valor recebido e a conversão esperada.
- Relatório final da execução.
- Histórico de importações.
- Possibilidade de retomar uma importação interrompida, sem duplicar registros.

Diferencie erros de validação, erros de transformação, referências não encontradas e erros de gravação.

Não registre senhas ou outros dados sensíveis nos logs.

## 12. Interface gráfica

Proponha uma interface desktop clara, adequada para uso técnico.

Considere as seguintes telas:

1. Cadastro de conexões.
2. Seleção da planilha e da aba.
3. Análise da estrutura da planilha.
4. Mapeamento de campos e seleção da origem dos valores.
5. Configuração de valores fixos e padrões.
6. Configuração de transformações.
7. Configuração de referências e consultas.
8. Definição das dependências.
9. Configuração da estratégia de gravação.
10. Pré-visualização e validação.
11. Execução e acompanhamento.
12. Histórico e relatório de importações.
13. Cadastro e gerenciamento dos perfis.

Utilize componentes compatíveis com Delphi 11. Se for necessário escolher entre VCL e outra tecnologia, apresente a recomendação e suas justificativas antes de implementar.

## 13. Requisitos técnicos e qualidade

A implementação deverá:

- Utilizar Delphi 11.
- Utilizar classes, interfaces e separação de responsabilidades.
- Evitar dependência direta da interface gráfica nas regras de negócio.
- Permitir substituir componentes de acesso a dados.
- Utilizar tratamento consistente de exceções.
- Liberar corretamente os recursos e objetos.
- Evitar carregar planilhas inteiras na memória quando o volume justificar processamento incremental.
- Ler o formato .xls (Excel 97-2003) sem depender de o Excel estar instalado na máquina, se possível.
- Tratar células vazias, mescladas, formatadas como texto, número ou data, e valores de data armazenados como número serial do Excel.
- Tratar colunas opcionais e linhas que não representam registros.
- Garantir que a aplicação não dependa de caminhos absolutos específicos da máquina.
- Incluir testes para transformações, mapeamentos, referências, valores fixos, valores padrão e dependências.
- Manter o núcleo do sistema independente dos ERPs específicos.

Não escolha bibliotecas de terceiros sem verificar sua compatibilidade com Delphi 11, sua licença e seus requisitos de instalação.

Não invente classes, métodos ou componentes que não existam na biblioteca escolhida.

## 14. Etapas de desenvolvimento

Não implemente tudo de uma vez.

### Etapa 1 — Análise e arquitetura

Apresente:

- Análise dos requisitos.
- Possíveis conflitos e riscos.
- Arquitetura proposta.
- Diagrama dos principais componentes.
- Modelo de dados para armazenar as configurações.
- Interfaces e responsabilidades.
- Estratégia para suportar diferentes bancos.
- Estratégia para armazenar origens de valores, padrões e transformações.
- Decisões técnicas que dependem de informações adicionais.

### Etapa 2 — Modelo de configuração

Defina as classes e estruturas que representam:

- Perfil de importação.
- Fonte de dados (planilha).
- Tabela de destino.
- Mapeamento de campos.
- Origem do valor.
- Valor fixo.
- Valor padrão e condições de aplicação.
- Transformação.
- Regra de referência.
- Dependência entre etapas.
- Estratégia de gravação.
- Histórico de execução.

Mostre como esses elementos se relacionam.

### Etapa 3 — Primeiro protótipo funcional

Implemente um fluxo mínimo que permita:

1. Conectar a um banco de destino.
2. Selecionar uma tabela.
3. Abrir uma planilha.
4. Mapear os campos.
5. Definir campos com valores fixos.
6. Definir valores padrão.
7. Converter tipos de dados.
8. Visualizar os valores transformados e suas origens.
9. Validar os dados.
10. Gravar os registros.
11. Salvar e carregar o perfil de importação.

### Etapa 4 — Relacionamentos e dependências

Implemente a resolução de referências, a captura de códigos internos e a importação de múltiplas tabelas em ordem configurável.

### Etapa 5 — Personalização e robustez

Adicione provedores de regras personalizadas, histórico, retomada, transações e recursos de desempenho.

Em cada etapa, apresente o código completo dos arquivos criados ou alterados, com seus respectivos nomes e caminhos. Explique como compilar e testar.

Não avance para uma etapa que dependa de decisões arquiteturais ainda não aprovadas.

## 15. Critérios de aceitação

A solução será considerada funcional quando for possível demonstrar o seguinte cenário:

Uma planilha contém clientes e outra contém lançamentos financeiros.

O importador cadastra os clientes, obtém os códigos internos atribuídos pelo ERP e utiliza esses códigos nos lançamentos financeiros.

A planilha contém datas em texto e valores monetários em formatos diferentes dos esperados pelo banco. As transformações são configuradas e validadas antes da gravação.

A planilha não contém todos os campos necessários para o ERP. O usuário consegue configurar valores fixos e padrões para preencher esses campos.

Um campo configurado com valor fixo recebe sempre o valor definido. Um campo configurado com valor padrão recebe esse valor apenas quando a condição configurada for atendida.

O usuário consegue visualizar os valores finais e identificar de onde cada valor foi obtido.

O usuário salva o perfil e consegue reutilizá-lo em outra execução, sem refazer os mapeamentos.

Se um cliente não for encontrado, o sistema identifica a pendência e impede que o lançamento seja gravado com um código inválido.

Se a execução for interrompida, o histórico permite identificar o que foi concluído e o que precisa ser retomado.

## Orientação inicial

Comece exclusivamente pela Etapa 1.

Não gere ainda todos os arquivos do sistema.

Primeiro, analise criticamente os requisitos e proponha uma arquitetura que seja realmente viável em Delphi 11. Destaque decisões que preciso tomar, alternativas relevantes e os riscos de cada abordagem.

Dê preferência a uma solução prática, extensível e sustentável, que possa ser utilizada durante anos para importar dados de diferentes clientes para os diversos ERPs da empresa.