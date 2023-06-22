/*

Cleaning data in SQL

*/

SELECT *
FROM dbo.NashvilleHousing2

-------------------------------------------------------------------------------------------------

--Standardize Date Format

SELECT SaleDate, CONVERT(Date,SaleDate)
FROM dbo.NashvilleHousing2

UPDATE dbo.NashvilleHousing2
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE dbo.NashvilleHousing2
ADD SaleDateConverted Date;

UPDATE NashvilleHousing2
SET SaleDateConverted = CONVERT(Date,SaleDate)

--drop SaleDate column ***
------------------------------------------------------------------------------------------------------

-- Populate Property Address data
-- filling null values with addresses

SELECT *
FROM dbo.NashvilleHousing2
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM dbo.NashvilleHousing2 a
JOIN dbo.NashvilleHousing2 b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM dbo.NashvilleHousing2 a
JOIN dbo.NashvilleHousing2 b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

-------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

SELECT *
FROM dbo.NashvilleHousing2

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress)) as Address2
FROM dbo.NashvilleHousing2

ALTER TABLE dbo.NashvilleHousing2
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing2
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1)

ALTER TABLE dbo.NashvilleHousing2
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing2
SET PropertySplitCity  = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress))

-- Alternative method

SELECT OwnerAddress
FROM NashvilleHousing2

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) AS address,
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) AS city,
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) AS state
FROM NashvilleHousing2

ALTER TABLE dbo.NashvilleHousing2
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing2
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

ALTER TABLE dbo.NashvilleHousing2
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing2
SET OwnerSplitCity  = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)


ALTER TABLE dbo.NashvilleHousing2
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing2
SET OwnerSplitState  = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) 

-----------------------------------------------------------------------------------------------------------------

--Change Y and N to Yes and No in "Sold As Vacant" field

SELECT Distinct (SoldAsVacant), COUNT(SoldAsVacant)
from NashvilleHousing2
GROUP BY SoldAsVacant
ORDER BY 2 

SELECT SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
from NashvilleHousing2
 
UPDATE NashvilleHousing2
SET SoldAsVacant = 
	   CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
from NashvilleHousing2

------------------------------------------------------------------------------------------------------------

--Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice,
				 SaleDate, 
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM NashvilleHousing2
)
DELETE
--SELECT * (USE THIS FOR CHECKING DUPLICATES)
FROM RowNumCTE
WHERE row_num > 1

---------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

SELECT * 
FROM NashvilleHousing2


ALTER TABLE NashvilleHousing2
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress


ALTER TABLE NashvilleHousing2
DROP COLUMN SaleDate