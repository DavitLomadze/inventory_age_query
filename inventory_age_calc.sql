-- cte
WITH
-- list skus and dates
sku_year_month AS (
SELECT DISTINCT "sku" AS "sku", "year_month"
FROM inventory i
CROSS JOIN 
(
SELECT DISTINCT CAST("year" AS TEXT) || '-' || CAST("month" AS TEXT) AS "year_month" FROM inventory i2 
) dates
WHERE 
warehouse IN (
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
	'1610990100 - პეკინი საწყობი')
	ORDER BY "sku"	
),
-- inventory by dates
inv AS(
SELECT 
	"sku",
	"product_name",
	"category",
	"type",
    CAST("year" AS TEXT) || '-' || CAST("month" AS TEXT) AS "year_month",
	SUM("cogs") AS "inv_cogs",
	SUM("quantity") AS "inv_quantity"
FROM inventory i 
WHERE
warehouse IN (
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
	'1610990100 - პეკინი საწყობი')
GROUP BY "year_month", "sku"
),
-- add orders
orders AS(
	SELECT 
		"შტრიხკოდი" AS "sku",
		CAST(strftime('%Y', "შემოსვლის თარიღი") AS TEXT) || '-' || CAST(strftime('%m', "შემოსვლის თარიღი") + 0 AS TEXT) AS "year_month", 
		SUM("თვითღირებულება (შესყიდვები)") AS "ordered_cogs",
		SUM("რაოდენობა (შესყიდვები)") AS "ordered_quantity"
	FROM containers c
	WHERE "შემოსვლის თარიღი" < '2024-04-01'
	GROUP BY "year_month", "sku"
),
-- add sales
sold AS(
	SELECT 
		CAST(strftime('%Y', "date") AS TEXT) || '-' || CAST(strftime('%m', "date") + 0 AS TEXT) AS "year_month",
		"sku",
		SUM("cogs") AS "sold_cogs",
		SUM("quantity") AS "sold_quantity"
	FROM sales s
	WHERE "date" < '2024-04-01'
	GROUP BY "year_month", "sku"
)

/*
 *  inventory is the main source of skus
 *  left join everything to it
 */
SELECT
    sym.*,
    COALESCE(inv.inv_cogs, 0) AS inv_cogs,
    COALESCE(inv.inv_quantity, 0) AS inv_quantity,
    COALESCE(o.ordered_cogs, 0) AS ordered_cogs,
    COALESCE(o.ordered_quantity, 0) AS ordered_quantity,
    COALESCE(s.sold_cogs, 0) AS sold_cogs,
    COALESCE(s.sold_quantity, 0) AS sold_quantity,
    COALESCE(o.year_month, 'n/o') AS order_date,
    COALESCE(s.year_month, 'n/s') AS sales_date
FROM sku_year_month sym
LEFT JOIN inv ON inv.sku = sym.sku AND inv.year_month = sym.year_month
LEFT JOIN orders o ON sym.sku = o.sku AND sym.year_month = o.year_month
LEFT JOIN sold s ON sym.sku = s.sku AND sym.year_month = s.year_month
WHERE sym.sku = '6942191636771'
ORDER BY "year_month";
