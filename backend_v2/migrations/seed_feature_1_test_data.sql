INSERT INTO products (
    id,
    name,
    brand,
    category,
    description,
    ingredients,
    nutrition_info,
    storage_instruction,
    manufacturer,
    country_of_origin,
    product_source,
    sku,
    barcode,
    barcode_type
)
VALUES (
    gen_random_uuid(),
    'Amul Taaza Toned Milk 500ml',
    'Amul',
    'Dairy',
    'Toned milk product',
    'Toned milk',
    '{"energy": "58 kcal", "protein": "3.1g", "fat": "3g"}',
    'Keep refrigerated',
    'Amul',
    'India',
    'LOCAL_DATABASE',
    'AMUL-TAAZA-500ML',
    '8901262010011',
    'EAN_13'
)
ON CONFLICT DO NOTHING;

INSERT INTO product_identifiers (
    product_id,
    identifier_type,
    identifier_value,
    is_primary,
    source
)
SELECT
    id,
    'EAN_13',
    '8901262010011',
    TRUE,
    'LOCAL_DATABASE'
FROM products
WHERE name = 'Amul Taaza Toned Milk 500ml'
ON CONFLICT DO NOTHING;
