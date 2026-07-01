from app.schemas.alert_schema import AlertResult, Alert, AlertCode, AlertSeverity
from app.schemas.validation_schema import ValidationResult, ValidationStatus

class AlertService:
    def generate_alerts(self, validation_result: ValidationResult) -> AlertResult:
        alerts = []
        
        if not validation_result:
            return AlertResult(alerts=[], total_alerts=0, highest_severity=None)

        try:
            # 1. BARCODE_INVALID
            if validation_result.barcode.status == ValidationStatus.ERROR:
                alerts.append(Alert(
                    code=AlertCode.BARCODE_INVALID,
                    severity=AlertSeverity.CRITICAL,
                    message="Barcode is missing or invalid.",
                    recommended_action="Rescan the barcode."
                ))

            # 2. PRODUCT_NOT_FOUND
            if validation_result.product.status == ValidationStatus.ERROR:
                alerts.append(Alert(
                    code=AlertCode.PRODUCT_NOT_FOUND,
                    severity=AlertSeverity.WARNING,
                    message="Product could not be found in local or external databases.",
                    recommended_action="Enter product details manually or try another barcode."
                ))

            # 3. MFG_NOT_FOUND
            if validation_result.manufacturing.status == ValidationStatus.WARNING and "missing" in validation_result.manufacturing.message.lower():
                alerts.append(Alert(
                    code=AlertCode.MFG_NOT_FOUND,
                    severity=AlertSeverity.INFO,
                    message="Manufacturing date was not detected.",
                    recommended_action="Manually verify the manufacturing date if needed."
                ))

            # 4. EXPIRY_NOT_FOUND & 5. INVALID_DATE_SEQUENCE
            if validation_result.expiry.status == ValidationStatus.ERROR:
                msg = validation_result.expiry.message.lower()
                if "after manufacturing" in msg:
                    alerts.append(Alert(
                        code=AlertCode.INVALID_DATE_SEQUENCE,
                        severity=AlertSeverity.CRITICAL,
                        message="Expiry date is before the manufacturing date.",
                        recommended_action="Check the extracted dates for errors or rescan the label."
                    ))
                else:
                    alerts.append(Alert(
                        code=AlertCode.EXPIRY_NOT_FOUND,
                        severity=AlertSeverity.CRITICAL,
                        message="Expiry date is missing or invalid.",
                        recommended_action="Rescan the expiry label or enter it manually."
                    ))

            # 6. MRP_NOT_FOUND
            if validation_result.pricing.status == ValidationStatus.WARNING and "missing" in validation_result.pricing.message.lower():
                alerts.append(Alert(
                    code=AlertCode.MRP_NOT_FOUND,
                    severity=AlertSeverity.INFO,
                    message="MRP (price) was not found.",
                    recommended_action="Enter the price manually if tracking is required."
                ))

            # 7. LOW_OCR_CONFIDENCE
            if validation_result.ocr.status in [ValidationStatus.WARNING, ValidationStatus.ERROR]:
                severity = AlertSeverity.CRITICAL if validation_result.ocr.status == ValidationStatus.ERROR else AlertSeverity.WARNING
                alerts.append(Alert(
                    code=AlertCode.LOW_OCR_CONFIDENCE,
                    severity=severity,
                    message="OCR extraction had low confidence or failed.",
                    recommended_action="Ensure the label is clear and well-lit, then rescan."
                ))

        except Exception:
            # Never raise exceptions
            pass
            
        # Compute highest severity
        highest_severity = None
        if alerts:
            severities = [a.severity for a in alerts]
            if AlertSeverity.CRITICAL in severities:
                highest_severity = AlertSeverity.CRITICAL
            elif AlertSeverity.WARNING in severities:
                highest_severity = AlertSeverity.WARNING
            else:
                highest_severity = AlertSeverity.INFO
                
        return AlertResult(
            alerts=alerts,
            total_alerts=len(alerts),
            highest_severity=highest_severity
        )


def log_audit_event(
    db,
    event_type: str,
    entity_type: str | None = None,
    entity_id: str | None = None,
    actor_id: str | None = "system",
    actor_type: str | None = "system",
    before_state: dict | None = None,
    after_state: dict | None = None,
    change_summary: str | None = None,
):
    """Log a significant system action to the audit_logs table."""
    from app.models.audit_log import AuditLog
    try:
        log_entry = AuditLog(
            event_type=event_type,
            entity_type=entity_type,
            entity_id=entity_id,
            actor_id=actor_id,
            actor_type=actor_type,
            before_state=before_state,
            after_state=after_state,
            change_summary=change_summary,
        )
        db.add(log_entry)
        db.commit()
        db.refresh(log_entry)
        return log_entry
    except Exception as e:
        db.rollback()
        import logging
        logging.getLogger(__name__).warning(f"[AuditLog] Failed to write event {event_type}: {e}")
        return None
