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

SELECT *
FROM dbo.NashvilleHousing2
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM dbo.NashvilleHousing2 a
JOIN dbo.NashvilleHousing2 b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL





