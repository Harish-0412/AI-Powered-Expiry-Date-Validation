import os
import csv
import json
from pipeline.inference import run_pipeline

def evaluate_accuracy(image_dir, gt_csv_path, report_path='reports/accuracy_report.json', failures_path='reports/failures.csv'):
    # Load ground truth
    ground_truth = {}
    with open(gt_csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            ground_truth[row['filename']] = row['expiry_date']

    total = len(ground_truth)
    if total == 0:
        print("No ground truth data provided.")
        return

    detected_date_count = 0
    exact_match_count = 0
    month_match_count = 0
    status_correct_count = 0
    total_conf = 0.0
    
    failures = []
    
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    os.makedirs(os.path.dirname(failures_path), exist_ok=True)

    for filename, gt_date in ground_truth.items():
        image_path = os.path.join(image_dir, filename)
        if not os.path.exists(image_path):
            continue
            
        result = run_pipeline(image_path)
        
        pred_date = result.get('expiry_date')
        pred_status = result.get('status')
        conf = result.get('ocr_confidence', 0.0)
        total_conf += conf
        
        # Calculate ground truth status for comparison
        from datetime import datetime
        try:
            gt_dt = datetime.strptime(gt_date, "%Y-%m-%d")
            today = datetime.now()
            days_rem = (gt_dt - today).days
            if days_rem < 0:
                gt_status = "expired"
            elif days_rem <= 30: # Assuming default 30 for evaluation
                gt_status = "near_expiry"
            else:
                gt_status = "valid"
        except:
            gt_status = "undetected"

        if pred_date:
            detected_date_count += 1
            if pred_date == gt_date:
                exact_match_count += 1
                month_match_count += 1
            elif pred_date[:7] == gt_date[:7]: # YYYY-MM
                month_match_count += 1
                
        if pred_status == gt_status:
            status_correct_count += 1
            
        if pred_date != gt_date or pred_status != gt_status:
            reason = "undetected" if not pred_date else "wrong_date" if pred_date != gt_date else "wrong_status"
            failures.append({
                'filename': filename,
                'ground_truth_date': gt_date,
                'predicted_date': pred_date,
                'ground_truth_status': gt_status,
                'predicted_status': pred_status,
                'reason': reason
            })

    metrics = {
        "Date Detection Rate": detected_date_count / total * 100,
        "Exact Match Accuracy": exact_match_count / total * 100,
        "Month Match Accuracy": month_match_count / total * 100,
        "Status Accuracy": status_correct_count / total * 100,
        "Avg OCR Confidence": total_conf / total,
        "Failure Breakdown": {
            "undetected": sum(1 for f in failures if f['reason'] == 'undetected'),
            "wrong_date": sum(1 for f in failures if f['reason'] == 'wrong_date'),
            "wrong_status": sum(1 for f in failures if f['reason'] == 'wrong_status')
        }
    }

    with open(report_path, 'w') as f:
        json.dump(metrics, f, indent=4)
        
    with open(failures_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['filename', 'ground_truth_date', 'predicted_date', 'ground_truth_status', 'predicted_status', 'reason'])
        writer.writeheader()
        writer.writerows(failures)

    print("Evaluation Complete. Results saved to reports/")
    for k, v in metrics.items():
        if isinstance(v, float):
            print(f"{k}: {v:.2f}%" if "Rate" in k or "Accuracy" in k else f"{k}: {v:.4f}")
        else:
            print(f"{k}: {v}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--image_dir', type=str, required=True)
    parser.add_argument('--gt_csv', type=str, required=True)
    args = parser.parse_args()
    evaluate_accuracy(args.image_dir, args.gt_csv)
