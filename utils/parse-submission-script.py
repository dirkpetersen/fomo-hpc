import os
import re
from pathlib import Path
from typing import List, Tuple
import warnings

def check_filesystem_references(text: str) -> List[Tuple[str, bool]]:
    """
    Search for words starting with '/' and check if they are filesystem folders.
    
    Args:
        text (str): The input text to search for potential filesystem references
        
    Returns:
        List[Tuple[str, bool]]: List of tuples containing (path, exists_flag)
        
    Example:
        >>> text = "Check /etc and /nonexistent/path"
        >>> results = check_filesystem_references(text)
        >>> for path, exists in results:
        ...     if exists:
        ...         warnings.warn(f"Found reference to existing filesystem path: {path}")
    """
    # Regular expression to find words starting with /
    pattern = r'\b/\w+(?:/\w+)*\b'
    
    # Find all matches in the text
    potential_paths = re.findall(pattern, text)
    results = []
    
    for path in potential_paths:
        # Convert to Path object for robust handling
        path_obj = Path(path)
        
        # Check if path exists and is a directory
        exists = path_obj.exists() and path_obj.is_dir()
        
        # Store result
        results.append((path, exists))
        
        # Issue warning if path exists
        if exists:
            warnings.warn(
                f"Found reference to existing filesystem path: {path}",
                category=UserWarning
            )
            
    return results

def analyze_text(text: str, ignore_paths: List[str] = None) -> dict:
    """
    Analyze text for filesystem references with additional options and detailed reporting.
    
    Args:
        text (str): The input text to analyze
        ignore_paths (List[str], optional): List of paths to ignore
        
    Returns:
        dict: Analysis results including found paths and statistics
    """
    ignore_paths = set(ignore_paths or [])
    results = check_filesystem_references(text)
    
    # Prepare report
    report = {
        "total_references": len(results),
        "existing_paths": [],
        "nonexistent_paths": [],
        "ignored_paths": [],
        "statistics": {
            "total": len(results),
            "existing": 0,
            "nonexistent": 0,
            "ignored": 0
        }
    }
    
    # Process results
    for path, exists in results:
        if path in ignore_paths:
            report["ignored_paths"].append(path)
            report["statistics"]["ignored"] += 1
        elif exists:
            report["existing_paths"].append(path)
            report["statistics"]["existing"] += 1
        else:
            report["nonexistent_paths"].append(path)
            report["statistics"]["nonexistent"] += 1
    
    return report

# Example usage
if __name__ == "__main__":
    sample_text = """
    The configuration files are in /etc/config and logs are in /var/log.
    There's also a reference to /nonexistent/path here.
    """
    
    # Basic usage
    print("Basic check results:")
    results = check_filesystem_references(sample_text)
    for path, exists in results:
        print(f"Path: {path}, Exists: {exists}")
    
    # Advanced analysis
    print("\nDetailed analysis:")
    ignore_list = ["/etc/config"]  # Paths to ignore
    analysis = analyze_text(sample_text, ignore_paths=ignore_list)
    
    print(f"\nStatistics:")
    print(f"Total references found: {analysis['statistics']['total']}")
    print(f"Existing paths: {analysis['statistics']['existing']}")
    print(f"Nonexistent paths: {analysis['statistics']['nonexistent']}")
    print(f"Ignored paths: {analysis['statistics']['ignored']}")