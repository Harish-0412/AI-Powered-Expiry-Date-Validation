import uuid
from datetime import datetime, timezone
from typing import Optional, Any
from app.schemas.product_intelligence_schema import (
    ProductIntelligence, ScanInfo, BarcodeInfo, ProductInfo,
    ManufacturingInfo, ExpiryInfo, PricingInfo, BatchInfo, OcrInfo, MetadataInfo, LookupMetadata
)

class ProductIntelligenceService:
    def build_product_profile(
        self,
        barcode_data: Optional[Any] = None,
        product_lookup: Optional[Any] = None,
        ocr_data: Optional[Any] = None
    ) -> ProductIntelligence:

        scan_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc)

        scan_info = ScanInfo(scan_id=scan_id, timestamp=timestamp)

        # Barcode parsing
        barcode_info = BarcodeInfo()
        if barcode_data:
            barcode_info.value = getattr(barcode_data, 'value', None)
            barcode_info.barcode_type = getattr(barcode_data, 'barcode_type', None)
            barcode_info.length = getattr(barcode_data, 'length', None)
            barcode_info.country_prefix = getattr(barcode_data, 'country_prefix', None)
            barcode_info.country = getattr(barcode_data, 'country', None)
            barcode_info.manufacturer_code = getattr(barcode_data, 'manufacturer_code', None)
            barcode_info.product_code = getattr(barcode_data, 'product_code', None)
            barcode_info.check_digit = getattr(barcode_data, 'check_digit', None)
            barcode_info.checksum_valid = getattr(barcode_data, 'checksum_valid', None)

        # Product parsing
        product_info = ProductInfo()
        if product_lookup:
            product_info.name = getattr(product_lookup, 'product_name', None)
            product_info.brand = getattr(product_lookup, 'brand', None)
            product_info.category = getattr(product_lookup, 'category', None)
            product_info.subcategory = getattr(product_lookup, 'subcategory', None)
            product_info.quantity = getattr(product_lookup, 'quantity', None)
            product_info.weight = getattr(product_lookup, 'weight', None)
            product_info.ingredients = getattr(product_lookup, 'ingredients', None)
            product_info.nutrition = getattr(product_lookup, 'nutrition', None)
            product_info.packaging = getattr(product_lookup, 'packaging', None)
            product_info.image_urls = getattr(product_lookup, 'image_urls', [])
            product_info.country_of_sale = getattr(product_lookup, 'country_of_sale', None)
            product_info.labels = getattr(product_lookup, 'labels', None)
            product_info.product_url = getattr(product_lookup, 'product_url', None)

        # Manufacturing parsing
        manufacturing_info = ManufacturingInfo()
        if barcode_data:
            manufacturing_info.manufacturer_code = getattr(barcode_data, 'manufacturer_code', None)
        if product_lookup:
            manufacturer_name = getattr(product_lookup, 'manufacturer', None)
            if manufacturer_name:
                manufacturing_info.manufacturer_name = manufacturer_name

        expiry_info = ExpiryInfo()
        batch_info = BatchInfo()
        pricing_info = PricingInfo()
        ocr_info = OcrInfo()

        # ── Priority 1: GS1 barcode-embedded dates (ground truth) ────────────────
        # These come from Application Identifiers in DataMatrix/QR/GS1-128 barcodes:
        #   AI(11) = MFG date  |  AI(17) = Expiry  |  AI(15) = Best Before  |  AI(10) = Batch
        if barcode_data and getattr(barcode_data, 'is_gs1_barcode', False):
            bc_mfg    = getattr(barcode_data, 'manufacturing_date', None)
            bc_expiry = getattr(barcode_data, 'expiry_date', None)
            bc_bb     = getattr(barcode_data, 'best_before_date', None)
            bc_batch  = getattr(barcode_data, 'batch_number', None)
            bc_lot    = getattr(barcode_data, 'lot_number', None)

            if bc_mfg:
                manufacturing_info.manufacturing_date = str(bc_mfg)
            if bc_expiry:
                expiry_info.expiry_date = str(bc_expiry)
            if bc_bb:
                expiry_info.best_before_date = str(bc_bb)
            if bc_batch:
                batch_info.batch_number = bc_batch
                batch_info.lot_number = bc_lot or bc_batch

        # ── Priority 2: OCR-extracted fields (fill any gaps barcode didn't cover) ─
        if ocr_data:
            if isinstance(ocr_data, dict):
                detected_fields = ocr_data.get('detected_fields', {})
                if not manufacturing_info.manufacturing_date:
                    manufacturing_info.manufacturing_date = detected_fields.get('mfg_date') or ocr_data.get('mfg_date')
                if not expiry_info.expiry_date:
                    expiry_info.expiry_date = ocr_data.get('expiry_date')
                if not expiry_info.best_before_date:
                    expiry_info.best_before_date = ocr_data.get('best_before_date')
                expiry_info.exp_computed = bool(ocr_data.get('exp_computed', False))
                if not batch_info.batch_number:
                    batch_info.batch_number = ocr_data.get('batch_number')
                pricing_info.price = ocr_data.get('price')
                pricing_info.currency = ocr_data.get('currency')

                ocr_info.raw_text = ocr_data.get('raw_text')
                ocr_info.confidence = ocr_data.get('confidence')
                ocr_info.detected_fields = detected_fields
            else:
                detected_fields = getattr(ocr_data, 'detected_fields', {})
                if not manufacturing_info.manufacturing_date:
                    manufacturing_info.manufacturing_date = detected_fields.get('mfg_date') or getattr(ocr_data, 'mfg_date', None)
                if not expiry_info.expiry_date:
                    expiry_info.expiry_date = getattr(ocr_data, 'expiry_date', None)
                if not expiry_info.best_before_date:
                    expiry_info.best_before_date = getattr(ocr_data, 'best_before_date', None)
                expiry_info.exp_computed = bool(getattr(ocr_data, 'exp_computed', False))
                if not batch_info.batch_number:
                    batch_info.batch_number = getattr(ocr_data, 'batch_number', None)
                pricing_info.price = getattr(ocr_data, 'price', None)
                pricing_info.currency = getattr(ocr_data, 'currency', None)

                ocr_info.raw_text = getattr(ocr_data, 'raw_text', None)
                ocr_info.confidence = getattr(ocr_data, 'confidence', None)
                ocr_info.detected_fields = detected_fields

        # Metadata parsing
        metadata_info = MetadataInfo(
            source_barcode="Present" if barcode_data else "Missing",
            source_product=getattr(product_lookup, 'source', 'Missing') if product_lookup else "Missing",
            source_ocr=bool(ocr_data)
        )
        
        lookup_metadata = LookupMetadata()
        if product_lookup:
            lookup_metadata.provider = getattr(product_lookup, 'source', None)
            lookup_metadata.cache_status = getattr(product_lookup, 'cache_status', 'MISS')
            lookup_metadata.lookup_time_ms = getattr(product_lookup, 'lookup_time_ms', 0.0)

        return ProductIntelligence(
            scan=scan_info,
            barcode=barcode_info,
            product=product_info,
            manufacturing=manufacturing_info,
            expiry=expiry_info,
            pricing=pricing_info,
            batch=batch_info,
            ocr=ocr_info,
            metadata=metadata_info,
            lookup_metadata=lookup_metadata
        )
