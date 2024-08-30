# Relatório: Criação de Script SQL para Análise de Campanhas e Compras

## Descrição da Tarefa

A tarefa consistia em integrar dois datasets diferentes, um contendo informações sobre campanhas (Campaign Dataset) e outro sobre compras (Purchase Dataset), utilizando SQL para gerar uma tabela consolidada com as seguintes informações para cada cliente:

- `client_id`: Identificação do cliente.
- `total_price`: Total gasto pelo cliente, calculado como `(price * amount * discount_applied)`.
- `most_purchase_location`: Local mais utilizado pelo cliente para realizar compras (website, app, store).
- `first_purchase`: Data da primeira compra realizada pelo cliente.
- `last_purchase`: Data da última compra realizada pelo cliente.
- `most_campaign`: Campanha mais recebida pelo cliente.
- `quantity_error`: Quantidade de campanhas que retornaram o status "error" para o cliente.
- `date_today`: Data atual formatada como `YYYY-MM-DD`.
- `anomes_today`: Data atual formatada como `MMYYYY` (tipo `int`).

## Abordagem

### Escolha por uma Única Query

A solução foi implementada em uma única query SQL por diversas razões:

1. **Atomicidade:** Utilizar uma única query permite que todas as operações sejam realizadas em uma única execução, garantindo que os dados estejam sincronizados e evitando inconsistências.
2. **Simplicidade:** Um único comando `CREATE TABLE` facilita a manutenção do script e torna o código mais direto.
3. **Eficiência:** Reduzir a quantidade de queries e operações intermediárias minimiza a sobrecarga de processamento, especialmente ao lidar com grandes volumes de dados.

## Explicação da Query

Abaixo, é explicado como cada coluna foi tratada na query final.

---

### 1. `client_id`

Essa coluna foi simplesmente selecionada diretamente da tabela de compras (`purchases`), pois é o identificador principal de cada cliente.

`p.client_id`

---

### 2. `total_price`

Para calcular o total gasto por cliente, foi utilizada a função `SUM()` multiplicando o preço (`price`), a quantidade de itens (`amount`), e o desconto aplicado (`1 - discount_applied`). A função `ROUND()` foi utilizada para limitar o resultado a duas casas decimais.

`ROUND(SUM(p.price * p.amount * (1 - p.discount_applied)), 2) AS total_price`

---

### 3. `most_purchase_location`

Esta coluna identifica o local de compra mais frequente de cada cliente. Para isso, foi utilizada uma subquery que agrupa as compras por local (`purchase_location`), ordenando pelo número de ocorrências em ordem decrescente (`COUNT(*) DESC`), e selecionando o mais frequente com `LIMIT 1`.

`(SELECT purchase_location FROM purchases WHERE client_id = p.client_id GROUP BY purchase_location ORDER BY COUNT(*) DESC LIMIT 1) AS most_purchase_location`

---

### 4. `first_purchase`

A data da primeira compra foi obtida utilizando a função `MIN()` sobre a coluna `purchase_datetime`.

`MIN(p.purchase_datetime) AS first_purchase`

---

### 5. `last_purchase`

A data da última compra foi obtida utilizando a função `MAX()` sobre a mesma coluna `purchase_datetime`.

`MAX(p.purchase_datetime) AS last_purchase`

---

### 6. `most_campaign`

Para identificar a campanha mais recebida por cliente, foi utilizada uma subquery similar à do local de compra. As campanhas (`campaigns`) foram agrupadas pelo `id_campaign`, ordenando pelo número de ocorrências, e foi selecionada a campanha mais frequente.

`(SELECT c.id_campaign FROM campaigns c WHERE c.client_id = p.client_id GROUP BY c.id_campaign ORDER BY COUNT(*) DESC LIMIT 1) AS most_campaign`

---

### 7. `quantity_error`

Essa coluna conta o número de campanhas que tiveram o status de retorno "error" para cada cliente. Foi utilizada a função `COUNT()` dentro de uma subquery que filtra as campanhas pelo `client_id` e `return_status = 'error'`.

`(SELECT COUNT(*) FROM campaigns c WHERE c.client_id = p.client_id AND c.return_status = 'error') AS quantity_error`

---

### 8. `date_today`

A data atual foi obtida diretamente com a função `CURRENT_DATE()`.

`CURRENT_DATE() AS date_today`

---

### 9. `anomes_today`

Para obter o código de data no formato `MMYYYY`, foi utilizada uma combinação das funções `CONCAT()`, `LPAD()`, e `CAST()` para criar uma string concatenada com o mês (`MONTH()`) e o ano (`YEAR()`), que foi convertida para `INT`.

`CAST(CONCAT(LPAD(MONTH(CURRENT_DATE()), 2, '0'), YEAR(CURRENT_DATE())) AS INT) AS anomes_today`

---

## Conclusão

A implementação em uma única query SQL foi eficaz para atender aos requisitos da tarefa, proporcionando uma execução eficiente e coesa. Cada coluna foi tratada individualmente, utilizando subqueries e funções agregadas para garantir a precisão dos dados consolidados.
