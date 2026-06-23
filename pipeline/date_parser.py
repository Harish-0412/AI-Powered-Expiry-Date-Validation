import re
from dateutil import parser
from datetime import datetime

hindi_months = {
    'जनवरी': '01', 'फरवरी': '02', 'मार्च': '03', 'अप्रैल': '04', 
    'मई': '05', 'जून': '06', 'जुलाई': '07', 'अगस्त': '08', 
    'सितंबर': '09', 'अक्टूबर': '10', 'नवंबर': '11', 'दिसंबर': '12'
}

def parse_date(text):
    if not text:
        return None, "", "none"
        
    text_lower = text.lower()
    
    # Check for Hindi months
    for hi_month, mm in hindi_months.items():
        if hi_month in text:
            # Attempt to extract year around it
            year_match = re.search(r'\b(20\d{2})\b', text)
            day_match = re.search(r'\b(0?[1-9]|[12][0-9]|3[01])\b', text)
            yy = year_match.group(1) if year_match else str(datetime.now().year)
            dd = day_match.group(1).zfill(2) if day_match else "01"
            parsed_date = f"{yy}-{mm}-{dd}"
            return parsed_date, f"{dd} {hi_month} {yy}", "hindi_regex"

    # Standard patterns
    patterns = [
        r'\b(0?[1-9]|[12][0-9]|3[01])[-/](0?[1-9]|1[012])[-/](20\d{2})\b', # DD/MM/YYYY
        r'\b(20\d{2})[-/](0?[1-9]|1[012])[-/](0?[1-9]|[12][0-9]|3[01])\b', # YYYY/MM/DD
        r'\b(0?[1-9]|1[012])[-/](20\d{2})\b', # MM/YYYY
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text)
        if match:
            try:
                dt = parser.parse(match.group(0), fuzzy=True)
                return dt.strftime("%Y-%m-%d"), match.group(0), "pattern_scan"
            except:
                continue
                
    # Keyword guided
    keywords = ['exp', 'expiry', 'best before', 'use by']
    for kw in keywords:
        if kw in text_lower:
            idx = text_lower.find(kw)
            substring = text[idx:idx+20]
            try:
                dt = parser.parse(substring, fuzzy=True)
                return dt.strftime("%Y-%m-%d"), substring, "keyword_guided"
            except:
                continue

    return None, "", "none"
