SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_CREATECHARGE]
	@v_chg_idcharge int out,
	@v_chg_poids smallint = NULL,
	@v_chg_hauteur smallint = NULL,
	@v_chg_largeur smallint = NULL,
	@v_chg_longueur smallint = NULL,
	@v_chg_idsysteme bigint = NULL,
	@v_chg_idbase bigint = NULL,
	@v_chg_idsousbase bigint = NULL,
	@v_chg_niveau tinyint = NULL,
	@v_tag_idtypeagv tinyint = NULL,
	@v_accesbase bit = NULL,
	@v_chg_orientation smallint = 0,
	@v_chg_face bit = 0,
	@v_chg_code varchar(8000) = NULL,
	@v_chg_idproduit varchar(20) = NULL,
	@v_chg_idsymbole varchar(32) = NULL,
	@v_chg_idlegende int = NULL,
	@v_chg_idmenucontextuel int = NULL,
	@v_chg_idvue int = NULL,
	@v_chg_idgabarit tinyint = NULL,
	@v_chg_idemballage tinyint = NULL,
	@v_chg_stabilite smallint = NULL,
	@v_chg_position tinyint = NULL,
	@v_chg_vitessemaximale smallint = 0,
	@v_forcage bit = 0
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_local bit,
	@v_transaction varchar(32),
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_chg_positionprofondeur int,
	@v_chg_positionniveau int,
	@v_chg_positioncolonne int,
	@v_adr_type bit,
	@v_adr_idtypemagasin tinyint,
	@v_adr_autorisation bit,
	@v_adr_verification bit,
	@v_adr_rayonnage bit,
	@v_adr_gerbage bit,
	@v_adr_accumulation bit,
	@v_adr_emplacement bit,
	@v_hauteur smallint,
	@v_longueur smallint,
	@v_chg_couche tinyint,
	@v_chg_rang smallint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_EXISTANT tinyint,
	@CODE_KO_INEXISTANT tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_INATTENDU tinyint,
	@CODE_KO_INTERDIT tinyint

-- Déclaration des constantes de catégories
DECLARE
	@CATE_CHARGE tinyint

-- Déclaration des constantes de symbole
DECLARE
	@SYMB_CHARGE varchar(32)

-- Déclaration des constantes de légendes
DECLARE
	@LEGE_CHARGE smallint

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_AGV tinyint,
	@TYPE_INTERFACE tinyint,
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint

-- Déclaration des constantes d'états
DECLARE
	@ETAT_ENCOURS tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint
	
-- Déclaration des constantes de types de missions
DECLARE
	@TYPE_TRANSFERT tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_EXISTANT = 3
	SET @CODE_KO_INEXISTANT = 4
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INATTENDU = 16
	SET @CODE_KO_INTERDIT = 18
	SET @CATE_CHARGE = 5
	SET @SYMB_CHARGE = 'CHARGE_CHARGE'
	SET @LEGE_CHARGE = 5
	SET @TYPE_AGV = 1
	SET @TYPE_INTERFACE = 2
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4
	SET @ETAT_ENCOURS = 2
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @TYPE_TRANSFERT = 1

-- Initialisation des variables
	SET @v_transaction = 'CREATECHARGE'
	SET @v_error = 0
	SET @v_status = @CODE_KO
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'unicité de la charge
	IF ((@v_chg_code IS NULL) OR (@v_chg_code IS NOT NULL AND NOT EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_CODE = @v_chg_code)))
	BEGIN
		IF @v_chg_idsysteme IS NOT NULL AND @v_chg_idbase IS NOT NULL AND @v_chg_idsousbase IS NOT NULL
		BEGIN
			-- Récupération des informations de l'adresse de dépose
			SELECT @v_adr_type = ADR_TYPEADRESSE, @v_adr_idtypemagasin = ADR_IDTYPEMAGASIN, @v_adr_autorisation = ADR_AUTORISATIONDEPOSE, @v_adr_verification = ADR_VERIFICATION,
				@v_adr_rayonnage = ADR_RAYONNAGE, @v_adr_gerbage = ADR_GERBAGE, @v_adr_accumulation = ADR_ACCUMULATION, @v_adr_emplacement = ADR_EMPLACEMENT
				FROM INT_ADRESSE WHERE ADR_IDSYSTEME = @v_chg_idsysteme AND ADR_IDBASE = @v_chg_idbase AND ADR_IDSOUSBASE = @v_chg_idsousbase
			-- Contrôle de l'existence de l'adresse de dépose
			IF @v_adr_idtypemagasin IS NULL
				SET @v_status = @CODE_KO_INEXISTANT
			ELSE
			BEGIN
				-- Contrôle de cohérence de l'adresse de dépose
				IF @v_adr_idtypemagasin = @TYPE_AGV OR (@v_adr_idtypemagasin <> @TYPE_AGV
					AND @v_forcage = 0 AND (@v_adr_autorisation = 0 OR @v_adr_verification = 1))
					SET @v_status = @CODE_KO_INTERDIT
				ELSE
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE INNER JOIN INT_TACHE_MISSION ON TAC_IDMISSION = MIS_IDMISSION
						INNER JOIN ORDRE_AGV ON ORD_IDORDRE = TAC_IDORDRE WHERE MIS_IDTYPEMISSION = @TYPE_TRANSFERT
						AND TAC_IDSYSTEMEEXECUTION = @v_chg_idsysteme AND TAC_IDBASEEXECUTION = @v_chg_idbase AND TAC_IDSOUSBASEEXECUTION = @v_chg_idsousbase
						AND TAC_IDETATTACHE = @ETAT_ENCOURS AND ISNULL(TAC_ACCESBASE, 0) = ISNULL(@v_accesbase, 0))
						OR (@v_adr_idtypemagasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_adr_accumulation = 1 AND @v_adr_emplacement = 0)
					BEGIN		
						IF @v_adr_type = 1
						BEGIN
							IF @v_adr_idtypemagasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_adr_accumulation = 1
							BEGIN
								-- Récupérer les dimensions de la charge du gabarit ou de l'emballage
								SELECT @v_hauteur = HAUTEUR, @v_longueur = LONGUEUR FROM dbo.SPV_DIMENSIONCHARGE(@v_chg_hauteur, @v_chg_largeur, @v_chg_longueur, @v_chg_face,
									@v_chg_idgabarit, @v_chg_idemballage)
								SELECT @v_status = RETOUR, @v_chg_positionprofondeur = OFFSETPROFONDEUR, @v_chg_positionniveau = OFFSETNIVEAU, @v_chg_positioncolonne = OFFSETCOLONNE
									FROM dbo.SPV_OFFSETADRESSE(@v_tag_idtypeagv, @v_chg_idsysteme, @v_chg_idbase, @v_chg_idsousbase, @v_chg_niveau, @v_accesbase, @v_adr_idtypemagasin,
									@v_adr_rayonnage, @v_adr_gerbage, 1, @v_chg_idcharge, @v_hauteur, @v_longueur, @v_chg_position, @v_forcage)
								SET @v_error = @@ERROR
								IF @v_status = @CODE_OK AND @v_error = 0
									SELECT @v_chg_couche = COUCHE, @v_chg_rang = RANG
										FROM dbo.SPV_POSITIONCHARGE(@v_tag_idtypeagv, @v_chg_idsysteme, @v_chg_idbase, @v_chg_idsousbase, @v_accesbase, @v_adr_gerbage, @v_hauteur, @v_longueur, @v_chg_position,
										@v_chg_positionprofondeur, @v_chg_positionniveau)
							END
							ELSE IF (@v_adr_idtypemagasin IN (@TYPE_AGV, @TYPE_INTERFACE)) OR (@v_adr_idtypemagasin = @TYPE_STOCK AND @v_adr_accumulation = 0)
							BEGIN
								IF NOT EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE, INT_MISSION_VIVANTE WHERE CHG_IDSYSTEME = @v_chg_idsysteme AND CHG_IDBASE = @v_chg_idbase
									AND CHG_IDSOUSBASE = @v_chg_idsousbase AND MIS_IDCHARGE = CHG_IDCHARGE)
								BEGIN
									UPDATE CHARGE SET CHG_ADR_KEYSYS = NULL, CHG_ADR_KEYBASE = NULL, CHG_ADR_KEYSSBASE = NULL, CHG_ACONTROLER = 1
										FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_chg_idsysteme AND CHG_ADR_KEYBASE = @v_chg_idbase AND CHG_ADR_KEYSSBASE = @v_chg_idsousbase
									SET @v_error = @@ERROR
									IF @v_error = 0
										SET @v_status = @CODE_OK
									ELSE
										SET @v_status = @CODE_KO_SQL
								END
								ELSE
									SET @v_status = @CODE_KO_INATTENDU
							END
							ELSE
								SET @v_status = @CODE_KO_INATTENDU
						END
						ELSE
							SET @v_status = @CODE_OK
					END
					ELSE
						SET @v_status = @CODE_KO_INATTENDU
				END
			END
		END
		ELSE
			SET @v_status = @CODE_OK
		IF @v_status = @CODE_OK AND @v_error = 0
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_CATEGORIE_SYMBOLE WHERE ACM_SYMBOLE = @v_chg_idsymbole AND ACM_CATEGORIE = @CATE_CHARGE)
				SELECT @v_chg_idsymbole = @SYMB_CHARGE
			IF NOT EXISTS (SELECT 1 FROM LEGENDE WHERE LEG_ID = @v_chg_idlegende AND LEG_CATEGORIE = @CATE_CHARGE)
				SELECT @v_chg_idlegende = @LEGE_CHARGE
			INSERT INTO CHARGE (CHG_POIDS, CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_ORIENTATION, CHG_ADR_KEYSYS, CHG_ADR_KEYBASE, CHG_ADR_KEYSSBASE,
				CHG_IDCLIENT, CHG_POSX, CHG_POSY, CHG_POSZ, CHG_ACONTROLER, CHG_DATELASTOPER, CHG_TODESTROY, CHG_PRODUIT, CHG_SYMBOLE, CHG_LEGENDE, CHG_MENU_CONTEXTUEL, CHG_VUE,
				CHG_GABARIT, CHG_EMBALLAGE, CHG_FACE, CHG_COUCHE, CHG_RANG, CHG_AVALIDER, CHG_STABILITE, CHG_POSITION, CHG_VITESSEMAXIMALE)
				VALUES (@v_chg_poids, @v_chg_hauteur, @v_chg_largeur, @v_chg_longueur, @v_chg_orientation, @v_chg_idsysteme, @v_chg_idbase, @v_chg_idsousbase,
				@v_chg_code, ISNULL(@v_chg_positioncolonne, 0), ISNULL(@v_chg_positionprofondeur, 0), ISNULL(@v_chg_positionniveau, 0), 0, GETDATE(), 0, @v_chg_idproduit, @v_chg_idsymbole, @v_chg_idlegende,
				@v_chg_idmenucontextuel, @v_chg_idvue, @v_chg_idgabarit, @v_chg_idemballage, @v_chg_face, @v_chg_couche, @v_chg_rang, 0, @v_chg_stabilite, @v_chg_position, @v_chg_vitessemaximale)
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				SET @v_chg_idcharge = SCOPE_IDENTITY()
				SET @v_retour = @CODE_OK
			END
			ELSE
				SET @v_retour = @CODE_KO_SQL
		END
		ELSE
			SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
	END
	ELSE
		SET @v_retour = @CODE_KO_EXISTANT
	IF @v_retour <> @CODE_OK
	BEGIN
		SET @v_chg_idcharge = 0
		IF @v_local = 1
			ROLLBACK TRAN @v_transaction
	END
	ELSE IF @v_local = 1
		COMMIT TRAN @v_transaction
	RETURN @v_retour



