SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_UPDATEADRESSE
-- Paramètre d'entrée	: @v_adr_systeme : Clé système
--			  @v_adr_base : Clé base
--			  @v_adr_sousbase : Clé sous-base
--			  @v_adr_capacite : Calcul de la capacité
-- Paramètre de sortie	: 
-- Descriptif		: Mise à jour du nombre d'emplacement vide et occupé d'une adresse
--			  et de son état d'occupation (le nb d'emplacement vide dépend désormais des dimensions de la dernière charge déposée)
--			  sans tenir compte des trace_mission qui n'existent peut-être pas
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[SPV_UPDATEADRESSE]
	@v_adr_systeme bigint,
	@v_adr_base bigint,
	@v_adr_sousbase bigint,
	@v_adr_capacite bit
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_tag_idtypeagv tinyint = 0,
	@v_bas_type_magasin tinyint,
	@v_adr_emplacement_occupe_old smallint,
	@v_adr_emplacement_occupe_new smallint,
	@v_bas_accumulation bit,
	@v_bas_gerbage bit,
	@v_adr_type bit,
	@v_adr_emplacement_vide smallint,
	@v_chg_hauteur smallint,
	@v_chg_largeur smallint,
	@v_chg_longueur smallint,
	@v_chg_face bit,
	@v_chg_idgabarit tinyint,
	@v_chg_idemballage tinyint,
	@v_chg_position tinyint,
	@v_hauteur smallint,
	@v_longueur smallint

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_AGV tinyint,
	@TYPE_INTERFACE tinyint,
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint

-- Déclaration des constantes de types de traces
DECLARE
	@TYPE_EXECUTION int

-- Déclaration des constantes d'états d'occupations
DECLARE
	@ETAT_VIDE tinyint,
	@ETAT_OCCUPE tinyint,
	@ETAT_PLEIN tinyint

-- Définition des constantes
	SET @TYPE_AGV = 1
	SET @TYPE_INTERFACE = 2
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4
	SET @TYPE_EXECUTION = 7
	SET @ETAT_VIDE = 1
	SET @ETAT_OCCUPE = 2
	SET @ETAT_PLEIN = 3

	IF @v_adr_systeme IS NOT NULL AND @v_adr_base IS NOT NULL AND @v_adr_sousbase IS NOT NULL
	BEGIN
		SELECT @v_bas_type_magasin = BAS_TYPE_MAGASIN, @v_bas_accumulation = BAS_ACCUMULATION FROM BASE WHERE BAS_SYSTEME = @v_adr_systeme AND BAS_BASE = @v_adr_base
		SELECT @v_adr_type = ADR_TYPE, @v_adr_emplacement_vide = ADR_EMPLACEMENT_VIDE, @v_adr_emplacement_occupe_old = ADR_EMPLACEMENT_OCCUPE FROM ADRESSE WHERE ADR_SYSTEME = @v_adr_systeme AND ADR_BASE = @v_adr_base AND ADR_SOUSBASE = @v_adr_sousbase
		SELECT @v_adr_emplacement_occupe_new = COUNT(*) FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_systeme AND CHG_ADR_KEYBASE = @v_adr_base AND CHG_ADR_KEYSSBASE = @v_adr_sousbase
			AND CHG_TODESTROY = 0
		IF @v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1
		BEGIN
			IF @v_adr_emplacement_occupe_new > 0
			BEGIN
				IF @v_adr_type = 1
				BEGIN
					-- Récupérer les informations de la dernière charge déposée ou modifiée
					SELECT TOP 1 @v_chg_hauteur = CHG_HAUTEUR, @v_chg_largeur = CHG_LARGEUR, @v_chg_longueur = CHG_LONGUEUR, @v_chg_face = CHG_FACE,
						@v_chg_idgabarit = CHG_GABARIT, @v_chg_idemballage = CHG_EMBALLAGE, @v_chg_position = CHG_POSITION, @v_tag_idtypeagv = ISNULL(IAG_TYPE, 0)
						FROM CHARGE LEFT OUTER JOIN TRACE_MISSION ON TMI_IDCHARGE = CHG_ID AND TMI_TYPETRC = @TYPE_EXECUTION LEFT OUTER JOIN INFO_AGV ON IAG_ID = TMI_IDAGV
						WHERE CHG_ADR_KEYSYS = @v_adr_systeme AND CHG_ADR_KEYBASE = @v_adr_base AND CHG_ADR_KEYSSBASE = @v_adr_sousbase
						AND CHG_TODESTROY = 0 ORDER BY COALESCE(TMI_DATE, CHG_DATELASTOPER) DESC
					-- si aucun type AGV n'est trouve dans les traces mission, on le recupere par defaut dans les outils AGV en prenant l'outil le + contraignant
					if @v_tag_idtypeagv = 0
						select top 1  @v_tag_idtypeagv=tag_id from TYPE_AGV WHERE TAG_TYPE_OUTIL IN (1, 2) order by isnull(TAG_FOURCHE,0) desc
					-- Récupérer les dimensions de la charge du gabarit ou de l'emballage
					SELECT @v_hauteur = HAUTEUR, @v_longueur = LONGUEUR FROM dbo.SPV_DIMENSIONCHARGE(@v_chg_hauteur, @v_chg_largeur, @v_chg_longueur, @v_chg_face,
						@v_chg_idgabarit, @v_chg_idemballage)
					IF @v_adr_emplacement_vide IS NULL OR @v_adr_capacite = 1
						SELECT @v_adr_emplacement_vide = dbo.INT_GETCAPACITE(@v_adr_systeme, @v_adr_base, @v_adr_sousbase, @v_tag_idtypeagv, 0, @v_hauteur, NULL, @v_longueur, 0, @v_chg_position)
							+ dbo.INT_GETCAPACITE(@v_adr_systeme, @v_adr_base, @v_adr_sousbase, @v_tag_idtypeagv, 1, @v_hauteur, NULL, @v_longueur, 0, @v_chg_position)
					ELSE
						SET @v_adr_emplacement_vide = @v_adr_emplacement_vide - (@v_adr_emplacement_occupe_new - @v_adr_emplacement_occupe_old)
					UPDATE ADRESSE SET ADR_EMPLACEMENT_VIDE = @v_adr_emplacement_vide, ADR_EMPLACEMENT_OCCUPE = @v_adr_emplacement_occupe_new,
						ADR_ETAT_OCCUPATION = CASE WHEN @v_adr_emplacement_vide = 0 THEN @ETAT_PLEIN ELSE @ETAT_OCCUPE END
						WHERE ADR_SYSTEME = @v_adr_systeme AND ADR_BASE = @v_adr_base AND ADR_SOUSBASE = @v_adr_sousbase
				END
				ELSE
					UPDATE ADRESSE SET ADR_EMPLACEMENT_VIDE = NULL, ADR_EMPLACEMENT_OCCUPE = @v_adr_emplacement_occupe_new,
						ADR_ETAT_OCCUPATION = @ETAT_OCCUPE
						WHERE ADR_SYSTEME = @v_adr_systeme AND ADR_BASE = @v_adr_base AND ADR_SOUSBASE = @v_adr_sousbase
			END
			ELSE
				UPDATE ADRESSE SET ADR_EMPLACEMENT_VIDE = NULL, ADR_EMPLACEMENT_OCCUPE = 0, ADR_ETAT_OCCUPATION = @ETAT_VIDE
					WHERE ADR_SYSTEME = @v_adr_systeme AND ADR_BASE = @v_adr_base AND ADR_SOUSBASE = @v_adr_sousbase
		END
		ELSE IF @v_bas_type_magasin IN (@TYPE_AGV, @TYPE_INTERFACE) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_accumulation = 0)
		BEGIN
			IF @v_adr_type = 1
				UPDATE ADRESSE SET ADR_EMPLACEMENT_VIDE = CASE WHEN @v_adr_emplacement_occupe_new > 0 THEN 0 ELSE 1 END, ADR_EMPLACEMENT_OCCUPE = @v_adr_emplacement_occupe_new,
					ADR_ETAT_OCCUPATION = CASE WHEN @v_adr_emplacement_occupe_new = 0 THEN @ETAT_VIDE ELSE @ETAT_PLEIN END
					WHERE ADR_SYSTEME = @v_adr_systeme AND ADR_BASE = @v_adr_base AND ADR_SOUSBASE = @v_adr_sousbase
			ELSE
				UPDATE ADRESSE SET ADR_EMPLACEMENT_VIDE = NULL, ADR_EMPLACEMENT_OCCUPE = @v_adr_emplacement_occupe_new,
					ADR_ETAT_OCCUPATION = CASE WHEN @v_adr_emplacement_occupe_new = 0 THEN @ETAT_VIDE ELSE @ETAT_OCCUPE END
					WHERE ADR_SYSTEME = @v_adr_systeme AND ADR_BASE = @v_adr_base AND ADR_SOUSBASE = @v_adr_sousbase
		END
		ELSE
			UPDATE ADRESSE SET ADR_EMPLACEMENT_VIDE = NULL, ADR_EMPLACEMENT_OCCUPE = NULL, ADR_ETAT_OCCUPATION = NULL
				WHERE ADR_SYSTEME = @v_adr_systeme AND ADR_BASE = @v_adr_base AND ADR_SOUSBASE = @v_adr_sousbase
	END

