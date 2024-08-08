
WITH orders AS (
    -- container with columns sku, entry_date, ordered_cogs, ordered_quantity, cummulative both, age
    SELECT
        "შტრიხკოდი" AS "sku",
        "შიდა კოდი" AS "code",
        "შემოსვლის თარიღი" AS "entry_date",
        SUM("თვითღირებულება (შესყიდვები)") AS "order_cost",
        SUM("რაოდენობა (შესყიდვები)") AS "ordered_quantity",
        SUM("თვითღირებულება (შესყიდვები)") OVER(PARTITION BY "შტრიხკოდი" ORDER BY "შემოსვლის თარიღი" ASC) AS "cumulative_cost",
        SUM("რაოდენობა (შესყიდვები)") OVER(PARTITION BY "შტრიხკოდი" ORDER BY "შემოსვლის თარიღი" ASC) AS "cumulative_quant",
        CAST((JULIANDAY('now') - JULIANDAY("შემოსვლის თარიღი")) AS integer) AS "age"
    FROM containers c
    GROUP BY "შტრიხკოდი", "შემოსვლის თარიღი"
    ORDER BY "შტრიხკოდი", "შემოსვლის თარიღი"
),
sales_cte AS (
    -- total sales for sku-s that are in containers list
    SELECT
        "code",
        SUM("cogs") AS "cogs",
        SUM("quantity") AS "sold_quantity"
    FROM sales s
    WHERE "code" IN (SELECT DISTINCT "შიდა კოდი" FROM containers c)
    GROUP BY "code"
),

closing_inventory AS (
	-- closing inventory of products
	SELECT "sku", SUM("cogs") AS "cost_inv", SUM("quantity") AS "quantity_inv"
	FROM inventory i
	WHERE "year" = (select MAX("year") from inventory i2) AND
	"month" = (select max("month") from inventory i3 where "year" = (select MAX("year") from inventory i2))
	AND "warehouse" IN (
	'1610100100 - ისთ ფოინთი - ფილიალი 10',
	'1610090100 - პეკინი',
	'1610070100 - თბილისი მოლი - ფილიალი 7',
	'1610050100 - ბათუმი მაღაზია',
	'1610041100 - რუსთაველის - ფილიალი 8',
	'1610030100 - აღმაშენებელი - ფილიალი 3',
	'1610020100 - მარჯანიშვილი - ფილიალი 2',
	'1610010100 - პიქსელი - ფილიალი 1',
	'1610010000 - ცენტრალური საწყობი წერეთელი',
	'1610000200 - მარჯანიშვილი საწყობი',
	'1610000100 - პიქსელი საწყობი',
	'1610080100 - ბათუმი XS - ფილიალი',
	'1610011000 - ცენტრალური საწყობი (სანზონა)',
	'1610000500 - ბათუმი საწყობი',
	'1610011100 - ცენტრალური საწყობი (ლილო)',
	'1610110100 - ყაზბეგი',
	'1610000300 - აღმაშენებელი საწყობი',
	'1610111400 - ყაზბეგი საწყობი',
	'1610071400 - თბილისი მოლი საწყობი',
	'1610041500 - რუსთაველი 8 საწყობი',
	'1610011400 - ისთ ფოინთი საწყობი',
	'1610990100 - პეკინი საწყობი',
	'1610001300 - ჰოუმ მარტი',
	'1610001400 - გორი ფილიალი'
)
	GROUP BY "sku"
)

SELECT
    o.*,
    IFNULL(s1.cogs, 0) AS "cogs",
    IFNULL(s1.sold_quantity, 0) AS "quantity",
    IFNULL(cl_inv.cost_inv, 0) AS "cost_inv",
    IFNULL(cl_inv.quantity_inv, 0) AS "quantity_inv"
FROM orders o
LEFT JOIN sales_cte s1
ON s1.code = o.code
LEFT JOIN closing_inventory cl_inv
ON cl_inv.sku = o.sku
WHERE "cost_inv" != 0;
