No desenvolvimento da tarefa, foram utilizados os assistentes de IA ChatGPT e Gemini Chatbot para auxiliar na criação de um prompt específico. Esse prompt foi elaborado como uma instrução destinada ao Vertex AI, com o objetivo de converter automaticamente um payload em formato JSON em uma view, facilitando a visualização dos dados de forma automatizada:

`Generate SQLX scripts based on the provided JSON template, ensuring the following error prevention measures: use CREATE VIEW IF NOT EXISTS, cast columns to the specified data types, and ensure filters are properly formatted. Return only the complete view creation script.`

Posteriormente, foi gerado um JSON de exemplo para testes utilizando o CSV 'purchases_2024', que é o que a squad atualmente está manipulando em outras tarefas:

```
{
  "view_name": "client_purchase_summary",
  "base_table": "purchases_2023",
  "joins": [],
  "columns": [
    {"name": "client_id", "alias": "client_id", "type": "STRING"},
    {
      "name": "COUNT(DISTINCT purchase_id)",
      "alias": "total_purchases",
      "type": "INT"
    },
    {
      "name": "SUM(amount)",
      "alias": "total_items_purchased",
      "type": "INT"
    },
    {
      "name": "SUM(price * amount)",
      "alias": "total_revenue",
      "type": "FLOAT"
    },
    {
      "name": "AVG(discount_applied)",
      "alias": "average_discount",
      "type": "FLOAT"
    },
    {
      "name": "MAX(purchase_datetime)",
      "alias": "last_purchase_date",
      "type": "DATETIME"
    }
  ],
  "filters": [
    {"column": "purchase_datetime", "condition": ">= '2023-01-01'"}
  ],
  "group_by": ["client_id"],
  "order_by": [
    {"column": "total_revenue", "direction": "DESC"}
  ]
}
```
O VertexAI retornou o seguinte script para a criação da VIEW:

```sql
CREATE VIEW IF NOT EXISTS client_purchase_summary AS
SELECT
  CAST(client_id AS STRING) AS client_id,
  COUNT(DISTINCT purchase_id) AS total_purchases,
  SUM(amount) AS total_items_purchased,
  CAST(SUM(price * amount) AS FLOAT) AS total_revenue,
  CAST(AVG(discount_applied) AS FLOAT) AS average_discount,
  MAX(purchase_datetime) AS last_purchase_date
FROM
  purchases_2023
WHERE
  purchase_datetime >= '2023-01-01'
GROUP BY
  client_id
ORDER BY
  total_revenue DESC;
```

Antes de conseguir executar a query, foi preciso corrigir dois pontos: estava faltando o endereçamento de qual projeto estava salvo o dataset, e as colunas `total_revenue` e `average_discount` estavam em um tipo não aceito pelo BigQuery, sendo alteradas de `FLOAT` para `FLOAT64`.

```
CREATE VIEW IF NOT EXISTS `squadcalouros.client_purchase_summary` AS
SELECT
  CAST(client_id AS STRING) AS client_id,
  COUNT(DISTINCT purchase_id) AS total_purchases,
  SUM(amount) AS total_items_purchased,
  CAST(SUM(price * amount) AS FLOAT64) AS total_revenue,
  CAST(AVG(discount_applied) AS FLOAT64) AS average_discount,
  MAX(purchase_datetime) AS last_purchase_date
FROM
  `squadcalouros.squadcalouros.purchases`
WHERE
  purchase_datetime >= '2023-01-01'
GROUP BY
  client_id
ORDER BY
  total_revenue DESC;
```