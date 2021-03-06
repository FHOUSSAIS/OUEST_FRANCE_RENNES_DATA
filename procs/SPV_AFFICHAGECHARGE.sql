SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_AFFICHAGECHARGE
-- Paramètre d'entrée	: @v_iag_id : Identifiant AGV
--			  @v_lan_id : Identifiant langue
-- Paramètre de sortie	: 
-- Descriptif		: Gestion de l'affichage des informations liées aux charges transportées
--			  sur l'AGV
--			  La chaîne résultante est au format "Information1 = valeur1, Information2 = valeur2"
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_AFFICHAGECHARGE]
	@v_iag_id tinyint,
	@v_lan_id varchar(3),
	@v_retour int out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_error smallint,
	@v_affichage varchar(8000),
	@v_description varchar(8000),
	@v_information varchar(8000),
	@v_valeur varchar(8000),
	@v_afc_id int,
	@v_afc_sql varchar(8000),
	@v_afc_systeme bit,
	@v_adr_systeme bigint,
	@v_adr_base bigint,
	@v_adr_sousbase bigint,
	@v_chg_id int,
	@v_chg_idclient varchar(8000),
	@v_chg_poids smallint,
	@v_chg_hauteur smallint,
	@v_chg_largeur smallint,
	@v_chg_longueur smallint,
	@v_chg_produit varchar(8000),
	@v_chg_gabarit varchar(8000),
	@v_chg_emballage varchar(8000),
	@v_chg_stabilite smallint,
	@v_sql varchar(8000)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OUI tinyint,
	@CODE_NON tinyint

-- Déclaration des constantes de types de magasin ou d'affichage
DECLARE
	@MAG_AGV tinyint,
	@AFF_CHARGE tinyint,
	@AFF_POIDS tinyint,
	@AFF_HAUTEUR tinyint,
	@AFF_LARGEUR tinyint,
	@AFF_LONGUEUR tinyint,
	@AFF_PRODUIT tinyint,
	@AFF_GABARIT tinyint,
	@AFF_EMBALLAGE tinyint,
	@AFF_STABILITE tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_STOPPE tinyint,
	@ACTI_KO tinyint

-- Définition des constantes
	SET @CODE_OUI = 5
	SET @CODE_NON = 6
	SET @MAG_AGV = 1
	SET @AFF_CHARGE = 0
	SET @AFF_POIDS = 1
	SET @AFF_HAUTEUR = 2
	SET @AFF_LARGEUR = 3
	SET @AFF_LONGUEUR = 4
	SET @AFF_PRODUIT = 5
	SET @AFF_GABARIT = 6
	SET @AFF_EMBALLAGE = 7
	SET @AFF_STABILITE = 8
	SET @ETAT_STOPPE = 3
	SET @ACTI_KO = 1

-- Initialisation des la variables
	SET @v_retour = @CODE_NON
	SET @v_error = 0

	DECLARE @v_affichage_charge table (CHARGE int, SYSTEME bigint, BASE bigint, SOUSBASE bigint, AFFICHAGE varchar(3000), DESCRIPTION varchar(3000))
	IF EXISTS (SELECT 1 FROM AFFICHAGE_CHARGE WHERE AFC_ACTIF = 1)
	BEGIN
		CREATE TABLE #TMP (VALEUR varchar(8000))
		DECLARE c_affichage CURSOR LOCAL SCROLL FOR SELECT AFC_ID, AFC_SQL, AFC_SYSTEME, LIB_LIBELLE FROM AFFICHAGE_CHARGE, LIBELLE
			WHERE AFC_ACTIF = 1 AND LIB_TRADUCTION = AFC_TRADUCTION AND LIB_LANGUE = @v_lan_id
			ORDER BY AFC_ORDRE
		OPEN c_affichage
		DECLARE c_charge CURSOR LOCAL FAST_FORWARD FOR SELECT ADR_SYSTEME, ADR_BASE, ADR_SOUSBASE, CHG_ID,
			ISNULL(CHG_IDCLIENT, CHG_ID), CHG_POIDS, CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR,
			ISNULL((SELECT LIB_LIBELLE FROM LIBELLE WHERE LIB_TRADUCTION = PRO_TRADUCTION AND LIB_LANGUE = @v_lan_id), ''),
			ISNULL((SELECT LIB_LIBELLE FROM LIBELLE WHERE LIB_TRADUCTION = GBR_TRADUCTION AND LIB_LANGUE = @v_lan_id), ''),
			ISNULL((SELECT LIB_LIBELLE FROM LIBELLE WHERE LIB_TRADUCTION = EMB_TRADUCTION AND LIB_LANGUE = @v_lan_id), ''), CHG_STABILITE,
			(SELECT TOP 1 LIB_LIBELLE FROM MISSION, TACHE, ASSOCIATION_TACHE_ACTION_TACHE,
				DESC_ETAT_ACTION, LIBELLE WHERE MIS_IDETAT = @ETAT_STOPPE AND TAC_IDMISSION = MIS_IDMISSION AND ATA_IDTACHE = TAC_IDTACHE
				AND ATA_IDETAT = @ACTI_KO AND ATA_VALIDATION = 1 AND DEA_ID = ATA_DESC_ETAT_ACTION
				AND LIB_TRADUCTION = DEA_TRADUCTION AND LIB_LANGUE = @v_lan_id
				ORDER BY TAC_POSITION_TACHE, ATA_IDTYPEACTION)
			FROM BASE, ADRESSE, CHARGE LEFT OUTER JOIN PRODUIT ON PRO_ID = CHG_PRODUIT
			LEFT OUTER JOIN GABARIT ON GBR_ID = CHG_GABARIT LEFT OUTER JOIN EMBALLAGE ON EMB_ID = CHG_EMBALLAGE
			WHERE BAS_TYPE_MAGASIN = @MAG_AGV AND BAS_MAGASIN = @v_iag_id AND ADR_SYSTEME = BAS_SYSTEME AND ADR_BASE = BAS_BASE
			AND CHG_ADR_KEYSYS = ADR_SYSTEME AND CHG_ADR_KEYBASE = ADR_BASE
			AND CHG_ADR_KEYSSBASE = ADR_SOUSBASE AND CHG_TODESTROY = 0
		OPEN c_charge
		FETCH NEXT FROM c_charge INTO @v_adr_systeme, @v_adr_base, @v_adr_sousbase, @v_chg_id,
			@v_chg_idclient, @v_chg_poids, @v_chg_hauteur, @v_chg_largeur, @v_chg_longueur, @v_chg_produit,
			@v_chg_gabarit, @v_chg_emballage, @v_chg_stabilite, @v_description
		WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
		BEGIN
			SET @v_affichage = ''
			FETCH FIRST FROM c_affichage INTO @v_afc_id, @v_afc_sql, @v_afc_systeme, @v_information
			WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
			BEGIN
				IF @v_afc_systeme = 1
				BEGIN
					SET @v_valeur = ISNULL(CASE @v_afc_id WHEN @AFF_CHARGE THEN @v_chg_idclient
						WHEN @AFF_POIDS THEN CONVERT(varchar, @v_chg_poids)
						WHEN @AFF_HAUTEUR THEN CONVERT(varchar, @v_chg_hauteur)
						WHEN @AFF_LARGEUR THEN CONVERT(varchar, @v_chg_largeur)
						WHEN @AFF_LONGUEUR THEN CONVERT(varchar, @v_chg_longueur)
						WHEN @AFF_PRODUIT THEN CONVERT(varchar, @v_chg_produit)
						WHEN @AFF_GABARIT THEN CONVERT(varchar, @v_chg_gabarit)
						WHEN @AFF_EMBALLAGE THEN CONVERT(varchar, @v_chg_emballage)
						WHEN @AFF_STABILITE THEN CONVERT(varchar, @v_chg_stabilite) END, '')
				END
				ELSE
				BEGIN
					DELETE #TMP
					SET @v_afc_sql = REPLACE(UPPER(@v_afc_sql), ':[Charge]', CONVERT(varchar, @v_chg_id))
					EXEC LIB_SQLTRADUCTION @v_afc_sql, @v_lan_id, @v_sql out
					INSERT INTO #TMP EXEC (@v_sql)
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_valeur = ISNULL((SELECT TOP 1 VALEUR FROM #TMP), '')
				END
				SET @v_affichage = @v_affichage + @v_information + ' = ' + @v_valeur + ', '
				FETCH NEXT FROM c_affichage INTO @v_afc_id, @v_afc_sql, @v_afc_systeme, @v_information
			END
			IF @v_affichage <> ''
				SET @v_affichage = SUBSTRING(@v_affichage, 1, LEN(@v_affichage) - 1)
			INSERT INTO @v_affichage_charge (CHARGE, SYSTEME, BASE, SOUSBASE, AFFICHAGE, DESCRIPTION)
				VALUES (@v_chg_id, @v_adr_systeme, @v_adr_base, @v_adr_sousbase, @v_affichage, @v_description)
			FETCH NEXT FROM c_charge INTO @v_adr_systeme, @v_adr_base, @v_adr_sousbase, @v_chg_id,
				@v_chg_idclient, @v_chg_poids, @v_chg_hauteur, @v_chg_largeur, @v_chg_longueur, @v_chg_produit,
				@v_chg_gabarit, @v_chg_emballage, @v_chg_stabilite, @v_description
		END
		CLOSE c_charge
		DEALLOCATE c_charge
		CLOSE c_affichage
		DEALLOCATE c_affichage
		DROP TABLE #TMP
		IF @v_error = 0
			SET @v_retour = @CODE_OUI
	END
	SELECT CHARGE, SYSTEME, BASE, SOUSBASE, AFFICHAGE, DESCRIPTION FROM @v_affichage_charge ORDER BY SOUSBASE



