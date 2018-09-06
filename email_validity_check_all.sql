--Check email fields 1-3
-- unioned all to avoid creating 3 separate CTEs for each email field (additional tables with email fields could be appended here)
-- ordered CTE results by ContactID. Previous example had inconsistent ordering, causing performance hits
WITH CTE_Check AS
	(SELECT TOP 10000000 ContactId
			,1 AS FieldNumber
			,LTRIM(RTRIM(EMAIL)) AS EmailAddress
			,CASE
				WHEN LTRIM(RTRIM(EMAIL)) LIKE '[ /:,&*^%$#!+=|"][ ?><} {;]' THEN 1
				WHEN LEN(EMAIL)-1 <= charindex('.', EMAIL) THEN 2	--check for domain '%._' at end of string
				WHEN EMAIL LIKE '%@acdlabs.%' THEN 3 --filter out company addresses
				WHEN EMAIL NOT LIKE '[a-z,0-9,_,-]%@[a-z,0-9,_,-]%.[a-z][a-z]%'  THEN 4	--Invalid format
				ELSE 5 --OK
			END AS EmailQuality
		FROM sysdba.CONTACT
		WHERE NULLIF(RTRIM(EMAIL), '') IS NOT NULL
	UNION ALL
	SELECT TOP 10000000 ContactId
		,2 AS FieldNumber
		,LTRIM(RTRIM(SECONDARYEMAIL)) AS EmailAddress
		,CASE
			WHEN LTRIM(RTRIM(SECONDARYEMAIL)) LIKE '[ /:,&*^%$#!+=|"][ ?><} {;]' THEN 1
			WHEN LEN(SECONDARYEMAIL)-1 <= charindex('.', SECONDARYEMAIL) THEN 2	--check for domain '%._' at end of string
			WHEN SECONDARYEMAIL LIKE '%@acdlabs.%' THEN 3 --filter out company addresses
			WHEN SECONDARYEMAIL NOT LIKE '[a-z,0-9,_,-]%@[a-z,0-9,_,-]%.[a-z][a-z]%'  THEN 4	--Invalid format
			ELSE 5 --OK
		END AS EmailQuality
	FROM sysdba.CONTACT 
		WHERE NULLIF(RTRIM(SECONDARYEMAIL), '') IS NOT NULL
	UNION ALL
	SELECT TOP 10000000 ContactId
			,3 AS FieldNumber 
			,LTRIM(RTRIM(EMAIL3)) AS EmailAddress
			,CASE               	
				WHEN LTRIM(RTRIM(EMAIL3)) LIKE '[ /:,&*^%$#!+=|"][ ?><} {;]' THEN 1        
				WHEN LEN(EMAIL3)-1 <= charindex('.', EMAIL3) THEN 2	--check for domain '%._' at end of string
				WHEN EMAIL3 LIKE '%@acdlabs.%' THEN 3 --filter out company addresses
				WHEN EMAIL3 NOT LIKE '[a-z,0-9,_,-]%@[a-z,0-9,_,-,.]%.[a-z][a-z]%'  THEN 4	--Invalid format
				ELSE 5 --OK
			END AS EmailQuality
		FROM sysdba.CONTACT 
		WHERE NULLIF(RTRIM(EMAIL3), '') IS NOT NULL
		ORDER BY ContactId
			,FieldNumber
			,EmailQuality
	)
	--union any additional email fields if necessary


SELECT CC.CONTACTID
		,CC.EmailAddress
		,CC.FieldNumber
		,CC.EmailQuality

	FROM CTE_Check CC 
		INNER JOIN sysdba.CONTACT C
			ON CC.ContactId = C.ContactId
	WHERE EmailQuality IN (4,2,1)

	;

