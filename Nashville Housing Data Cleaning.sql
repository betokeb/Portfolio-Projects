/*
Cleaning Data in SQL Queries

The objective of this project is to clean the data and make it more usable

Original DataSet: Nashville Housing Data


*/

SELECT * 
FROM PortfolioProject..NashvilleHousing

------------------

-- 1. STANDARDIZE DATE FORMAT

SELECT SaleDate
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate DATE

-- 2. POPULATE PROPERTY ADDRESS DATA

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing AS a
JOIN PortfolioProject..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing AS a
JOIN PortfolioProject..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- 3. BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)

-- PropertyAddress
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+2,LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+2,LEN(PropertyAddress))

-- Owner Address
SELECT OwnerAddress
FROM NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'), 3) AS [Address],
PARSENAME(REPLACE(OwnerAddress,',','.'), 2) AS City,
PARSENAME(REPLACE(OwnerAddress,',','.'), 1) AS [State]
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1)

-- 4. BREAKING OUT OWNER NAME INTO INDIVIDUAL COLUMNS (NAME, LASTNAME)

SELECT OwnerName
FROM NashvilleHousing
WHERE OwnerName IS NOT NULL

SELECT 
PARSENAME(REPLACE(OwnerName,',','.'), 1) AS OwnerFirstName,
PARSENAME(REPLACE(OwnerName,',','.'), 2) AS OwnerLastName
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerFirstName NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerFirstName = PARSENAME(REPLACE(OwnerName,',','.'), 1)

ALTER TABLE NashvilleHousing
ADD OwnerLastName NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerLastName = PARSENAME(REPLACE(OwnerName,',','.'), 2)

-- 5. CHANGE Y AN N TO YES AND NO IN "SOLD AS VACANT" FIELD

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS [Count]
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant, 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END

-- 6. REMOVE DUPLICATE

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID) Row_Num
FROM PortfolioProject..NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE Row_Num > 1

-- 7. CREATE VIEW WITH CLEAN DATA

CREATE VIEW NashvilleHousing_Clean AS
SELECT [UniqueID ], ParcelID, PropertySplitAddress, PropertySplitCity, SaleDate, SalePrice, SoldAsVacant, OwnerFirstName, OwnerLastName 
FROM NashvilleHousing

SELECT *
FROM NashvilleHousing_Clean
ORDER BY ParcelID
