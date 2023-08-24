select * from 
Portfolio_projects1..NashvilleHousing; 


--------------------------------------------------------------------------------------------------------------------------------
-- Standardize Date format
select SaleDate , convert(date, SaleDate) 
from Portfolio_projects1..NashvilleHousing;



ALTER TABLE Portfolio_projects1..NashvilleHousing
ADD SaleDateConverted Date;


update Portfolio_projects1..NashvilleHousing
SET SaleDateConverted = convert(date, Saledate);

select SaleDateConverted , convert(date, SaleDate) 
from Portfolio_projects1..NashvilleHousing;

------------------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data


Select *
from Portfolio_projects1..NashvilleHousing 
order by ParcelID;

select nv1.ParcelID, nv1.PropertyAddress, nv2.ParcelID, nv2.PropertyAddress, ISNULL(nv1.PropertyAddress, nv2.PropertyAddress)
from Portfolio_projects1..NashvilleHousing nv1
Join Portfolio_projects1..NashvilleHousing nv2
on nv1.ParcelID = nv2.ParcelID
and nv1.[UniqueID] <> nv2.[UniqueID]
where nv1.PropertyAddress is null;

update nv1
SET PropertyAddress = ISNULL(nv1.PropertyAddress, nv2.PropertyAddress)
from Portfolio_projects1..NashvilleHousing nv1
join Portfolio_projects1..NashvilleHousing nv2
on nv1.ParcelID = nv2.ParcelID
and nv1.[UniqueID] = nv2.[UniqueID]
where nv1.PropertyAddress is null;

-------------------------------------------------------------------------------------------------------------------------------------

-- Breaking out address into individual columns (address, city, state)

Select PropertyAddress 
from Portfolio_projects1..NashvilleHousing

select 
substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
substring(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address

from Portfolio_projects1..NashvilleHousing; 

ALTER TABLE Portfolio_projects1..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE Portfolio_projects1..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

ALTER TABLE Portfolio_projects1..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE Portfolio_projects1..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));

select * from 
Portfolio_projects1..NashvilleHousing; 

select 
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
from Portfolio_projects1..NashvilleHousing;

ALTER TABLE Portfolio_projects1..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE Portfolio_projects1..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3);

ALTER TABLE Portfolio_projects1..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE Portfolio_projects1..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2);

ALTER TABLE Portfolio_projects1..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE Portfolio_projects1..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1);


select * from Portfolio_projects1..NashvilleHousing;

----------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to yes and no in "Sold as vacant" field

select Distinct(SoldAsVacant), Count(SoldAsVacant) As CountOfItem
from Portfolio_projects1..NashvilleHousing
Group by SoldAsVacant
Order by 2; 


Update Portfolio_projects1..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END;

select Distinct(SoldAsVacant), Count(SoldAsVacant) As CountOfItem
from Portfolio_projects1..NashvilleHousing
Group by SoldAsVacant
Order by 2; 

-------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
-- (By Assuming we dont have a unique id value)
-- Identify the duplicates
WITH RowNumCTE AS(
select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	Order By 
	UniqueID) row_num

from Portfolio_projects1..NashvilleHousing
)
Select * from RowNumCTE
where row_num > 1
Order by PropertyAddress;

---------------------------------------------------------------------------------------------------------------------------------------

-- Delete the recignosed duplicate rows

WITH RowNumCTE AS(
select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	Order By 
	UniqueID) row_num

from Portfolio_projects1..NashvilleHousing
)
DELETE from RowNumCTE
where row_num > 1 ; 

----------------------------------------------------------------------------------------------------------------------------------------

-- Check whether the duplicates are removed from the dataset


WITH RowNumCTE AS(
select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	Order By 
	UniqueID) row_num

from Portfolio_projects1..NashvilleHousing
)
Select * from RowNumCTE
where row_num > 1
Order by PropertyAddress;


-----------------------------------------------------------------------------------------------------------------------------------

-- Delete unused columns

ALTER TABLE Portfolio_projects1..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

select * from Portfolio_projects1..NashvilleHousing;


-------------------------------------------------------------------------------------------------------------------------------------

-- Data Analysis


-- 1. What are the frequent land types and their counts

select TOP 10 LandUse, Count(LandUse) As NoOfProperties
From Portfolio_projects1..NashvilleHousing
group by LandUse
order by NoOfProperties DESC;


-- 2. What are the Sales price range of different types of lands

select Distinct(LandUse), MAX(SalePrice) as Max_Price, Min(SalePrice) As Min_price, (MAx(SalePrice)- Min(SalePrice)) As Price_Range
From Portfolio_projects1..NashvilleHousing
group by LandUse
order by Price_Range DESC;


-- 3. Avergae land prices in regions

select  Distinct(PropertySplitCity), LandUse, AVG(LandValue) as Avg_LandValue, AVG(SalePrice) As Avg_SalePrice
From Portfolio_projects1..NashvilleHousing
group by PropertySplitCity, LandUse
order by Avg_LandValue DESC,Avg_SalePrice DESC; 

-- 4. Maximum landvalues by region

select  Distinct(LandUse), MAX(LandValue) as Max_LandValue, PropertySplitCity
From Portfolio_projects1..NashvilleHousing
group by LandUse, PropertySplitCity
order by Max_LandValue DESC; 


-- 5. How sales price changes with the facilities of lands 

select LandUse, SalePrice, BedRooms, FullBath, HalfBath 
From Portfolio_projects1..NashvilleHousing
Where LandUse IN ('SINGLE FAMILY', 'DUPLEX', 'APARTMENT: LOW RISE (BUILT SINCE 1960)','VACANT ZONED MULTI FAMILY','DORMITORY/BOARDING HOUSE','TRIPLEX','QUADPLEX')
order by SalePrice DESC; 


-- 6. How land value and sale price of the land change with the land area
SELECT
    LandUse,
    AVG(Acreage) AS Avg_Acreage,
    AVG(Saleprice) AS Avg_Saleprice,
    AVG(LandValue) AS Avg_LandValue
FROM
    Portfolio_projects1..NashvilleHousing
GROUP BY
    LandUse
ORDER BY
    LandUse;

-- 7. what are the existing sales and land value differences in different regions
select LandUse, max(SalePrice) as Max_SalePrice, max(LandValue) AS Max_LandValue, PropertysplitCity
from Portfolio_projects1..Nashvillehousing
group by LandUse, PropertySplitCity;



-- 8. Does land prices change with the time in single family house?

Select SaleDateConverted, AVG(Saleprice) As Average_SalePrice
from Portfolio_projects1..NashvilleHousing
where LandUse= 'Single Family'
group by SaleDateConverted
order by SaleDateConverted; 


------------------------------------------------------------------------------------------------------------------------------------
