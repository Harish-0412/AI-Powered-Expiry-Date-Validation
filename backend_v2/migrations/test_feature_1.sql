SELECT * FROM products WHERE name = 'Amul Taaza Toned Milk 500ml';

SELECT 
    p.id,
    p.name,
    p.brand,
    p.category,
    pi.identifier_type,
    pi.identifier_value
FROM products p
JOIN product_identifiers pi
ON p.id = pi.product_id
WHERE pi.identifier_value = '8901262010011';

SELECT *
FROM products
WHERE name ILIKE '%Amul%';
