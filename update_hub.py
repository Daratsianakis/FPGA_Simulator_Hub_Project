#!/usr/bin/env python3
import os
import json

def generate_manifest():
    root_dir = "."
    project_data = {}

    # Scan directories
    for item in sorted(os.listdir(root_dir)):
        if os.path.isdir(item) and item.startswith("Project_"):
            # Find HTML files inside
            html_files = [f for f in sorted(os.listdir(item)) if f.endswith(".html")]
            if html_files:
                project_data[item] = html_files

    # Write JS manifest
    manifest_path = "projects_data.js"
    with open(manifest_path, "w") as f:
        f.write(f"const projectData = {json.dumps(project_data, indent=4)};\n")
    
    print(f"Manifest successfully generated with {len(project_data)} projects.")

if __name__ == "__main__":
    generate_manifest()
