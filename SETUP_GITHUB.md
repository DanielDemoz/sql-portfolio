# GitHub Setup Instructions

## Step 1: Create Repository on GitHub

1. Go to https://github.com/new
2. Repository name: `sql-portfolio`
3. Description: `Advanced SQL portfolio showcasing database design, complex queries, and business analytics`
4. Make it **Public**
5. **DO NOT** initialize with README (we already have one)
6. Click "Create repository"

## Step 2: Initialize and Push

Open your terminal in this directory and run:

```bash
# Navigate to project directory (if not already there)
cd "c:\Users\asbda\GitHub all\DanDemoz\sql-portfolio"

# Initialize git
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: SQL Portfolio with advanced queries and database design"

# Add remote (replace YOUR_USERNAME with DanielDemoz)
git remote add origin https://github.com/DanielDemoz/sql-portfolio.git

# Rename branch to main
git branch -M main

# Push to GitHub
git push -u origin main
```

## Step 3: Verify

1. Refresh your GitHub repository page
2. You should see all files uploaded
3. The README.md will display automatically

## Step 4: Pin Repository

1. Go to your GitHub profile: https://github.com/DanielDemoz
2. Click "Customize your pins"
3. Select this repository
4. Save

Done! ✅

