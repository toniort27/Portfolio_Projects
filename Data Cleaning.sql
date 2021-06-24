-- Starting the project with some data cleaning trough queries 

Select *
From PortfolioProject..NashvilleHousing

-- Checking the table we can see the Date is not standard. Let's standarize it

ALTER TABLE NashvilleHousing
Add NewSaleDate Date;

Update NashvilleHousing
Set NewSaleDate = CONVERT(Date, SaleDate)

Select NewSaleDate
From PortfolioProject..NashvilleHousing

-- Analizing PropertyAddress column

Select PropertyAddress
From PortfolioProject..NashvilleHousing
Where PropertyAddress is null 
Order by ParcelID

-- Studying the table we can check that there are some repeating properties given that the ParcelID is the same 

Select *
From PortfolioProject..NashvilleHousing
--Where PropertyAddress is null 
Order by ParcelID

/* 

Since we in fact have a reference to fill the PropertyAddress column,
we will join the table with itself to fill the null spaces

*/

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
Join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID 
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

-- Since it worked, let's update the table and fill up those nulls

Update a 
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

/*

Now, since Address is currently composed of address and city, let's break that down into
two columns

*/

Select PropertyAddress
From PortfolioProject..NashvilleHousing
--Where PropertyAddress is null 
--Order by ParcelID

Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
From PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
Add PropertySplitAddress Nvarchar (255);

Update PortfolioProject..NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) 

ALTER TABLE PortfolioProject..NashvilleHousing
Add PropertySplitCity Nvarchar (255);

Update PortfolioProject..NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- Let's check the result

Select *
From PortfolioProject..NashvilleHousing

-- Perfect. We now have two separate columns to check the address and the city of the properties in the data set.

/* 

We have another column with a similar problem; OwnerAddress.
Let's try a different approach for this one

*/


Select OwnerAddress
From PortfolioProject..NashvilleHousing
-- Where OwnerAddress is not null 

-- We can see that this column not only has the city, but also the state. Let's fix that

Select 
PARSENAME(REPLACE(OwnerAddress,',','.'),3)
,PARSENAME(REPLACE(OwnerAddress,',','.'),2)
,PARSENAME(REPLACE(OwnerAddress,',','.'),1)
From PortfolioProject..NashvilleHousing


ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitAddress Nvarchar (255);

Update PortfolioProject..NashvilleHousing
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3) 

ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitCity Nvarchar (255);

Update PortfolioProject..NashvilleHousing
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2) 

ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitState Nvarchar (255);

Update PortfolioProject..NashvilleHousing
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

-- Perfect. Now that info is much mure usable being split into three individual columns

/*

Now let's dig into the SoldAsVacant column.
Currently is not standarized into two variables. Let's standarize that column

*/

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PortfolioProject..NashvilleHousing
Group By SoldAsVacant
Order by 2


Update PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'Yes'
	When SoldAsVacant = 'N' Then 'No'
	ELSE SoldAsVacant
	END

-- Done! Now we only have 'Yes' or 'No' in the column

-- Now let's remove duplicates that may remain in our table

With RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				Order By 
					UniqueID
					) row_num
From PortfolioProject..NashvilleHousing
--Order by ParcelID
)
Delete 
From RowNumCTE
Where row_num > 1
--Order by PropertyAddress

/* 
Great! Finally let's delete the columns 
we are no longer gonna use
*/ 

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, SaleDate, TaxDistrict, PropertyAddress

Select *
From PortfolioProject..NashvilleHousing

-- That's it!