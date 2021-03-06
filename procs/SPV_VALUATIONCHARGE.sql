SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_VALUATIONCHARGE
-- Paramètre d'entrée	: @v_chg_idcharge : Identifiant de la charge
--			  @v_ata_idaction : Identifiant action
--			  @v_ata_resultat : Résultat
-- Paramètre de sortie	: @v_ata_idetat : Statut
--			  @v_ata_iddescription : Description
--			  Code de retour par défaut
--			    - @CODE_OK : L'évaluation a eu lieu
--			    - @CODE_KO : L'évaluation n'a pas eu lieu
--			    - @CODE_KO_SQL : Une erreur SQL a eu lieu
-- Descriptif		: Cette procédure évalue une charge
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_VALUATIONCHARGE]
	@v_chg_idcharge varchar(20),
	@v_ata_idaction int,
	@v_ata_idetat tinyint out,
	@v_ata_resultat varchar(32),
	@v_ata_iddescription tinyint out,
	@v_ata_validation bit out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_error int,
	@v_retour int,
	@v_chg_code varchar(8000)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'actions
DECLARE
	@ACTI_IDENTIFICATION smallint,
	@ACTI_PESEE smallint,
	@ACTI_LONGUEUR smallint,
	@ACTI_LARGEUR smallint,
	@ACTI_HAUTEUR smallint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ACTI_OK tinyint,
	@ACTI_KO tinyint,
	@DESC_NON_INDEFINI tinyint,
	@DESC_DOUBLON_CAB tinyint,
	@DESC_CAB_INATTENDU tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @ACTI_IDENTIFICATION = 8
	SET @ACTI_PESEE = 128
	SET @ACTI_LONGUEUR = 512
	SET @ACTI_LARGEUR = 1024
	SET @ACTI_HAUTEUR = 2048
	SET @ACTI_OK = 0
	SET @ACTI_KO = 1
	SET @DESC_NON_INDEFINI = 1
	SET @DESC_DOUBLON_CAB = 3
	SET @DESC_CAB_INATTENDU = 5

-- Initialisation de la variable de retour
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	IF @v_ata_idetat = @ACTI_OK
	BEGIN
		IF @v_ata_idaction = @ACTI_IDENTIFICATION
		BEGIN
			SELECT @v_chg_code = CHG_IDCLIENT FROM CHARGE WHERE CHG_ID = @v_chg_idcharge AND CHG_TODESTROY = 0
			IF @v_chg_code IS NOT NULL
			BEGIN
				IF @v_chg_code = @v_ata_resultat
				BEGIN
					SET @v_ata_iddescription = @DESC_NON_INDEFINI
					SET @v_ata_validation = 0
					SET @v_retour = @CODE_OK
				END
				ELSE
				BEGIN
					SET @v_ata_idetat = @ACTI_KO
					SET @v_ata_iddescription = @DESC_CAB_INATTENDU
					SET @v_ata_validation = 1
					UPDATE CHARGE SET CHG_AVALIDER = @v_ata_validation WHERE CHG_ID = @v_chg_idcharge
					IF @@ERROR <> 0
						SET @v_retour = @CODE_KO_SQL
					ELSE
						SET @v_retour = @CODE_OK
				END
			END
			ELSE
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM CHARGE WHERE CHG_IDCLIENT = @v_ata_resultat AND CHG_TODESTROY = 0)
				BEGIN
					SET @v_ata_iddescription = @DESC_NON_INDEFINI
					SET @v_ata_validation = 0
					UPDATE CHARGE SET CHG_IDCLIENT = @v_ata_resultat WHERE CHG_ID = @v_chg_idcharge
					IF @@ERROR <> 0
						SET @v_retour = @CODE_KO_SQL
					ELSE
						SET @v_retour = @CODE_OK
				END
				ELSE
				BEGIN
					SET @v_ata_idetat = @ACTI_KO
					SET @v_ata_iddescription = @DESC_DOUBLON_CAB
					SET @v_ata_validation = 1
					UPDATE CHARGE SET CHG_AVALIDER = @v_ata_validation WHERE CHG_ID = @v_chg_idcharge
					IF @@ERROR <> 0
						SET @v_retour = @CODE_KO_SQL
					ELSE
						SET @v_retour = @CODE_OK
				END
			END
		END
		ELSE
		BEGIN
			SET @v_ata_validation = 0
			IF @v_ata_idaction = @ACTI_PESEE
				UPDATE CHARGE SET CHG_POIDS = @v_ata_resultat WHERE CHG_ID = @v_chg_idcharge
			ELSE IF @v_ata_idaction = @ACTI_LONGUEUR
				UPDATE CHARGE SET CHG_LONGUEUR = @v_ata_resultat WHERE CHG_ID = @v_chg_idcharge
			ELSE IF @v_ata_idaction = @ACTI_LARGEUR
				UPDATE CHARGE SET CHG_LARGEUR = @v_ata_resultat WHERE CHG_ID = @v_chg_idcharge
			ELSE IF @v_ata_idaction = @ACTI_HAUTEUR
				UPDATE CHARGE SET CHG_HAUTEUR = @v_ata_resultat WHERE CHG_ID = @v_chg_idcharge
			IF @@ERROR <> 0
				SET @v_retour = @CODE_KO_SQL
			ELSE
				SET @v_retour = @CODE_OK
		END
	END
	ELSE
	BEGIN
		IF @v_ata_iddescription <> @DESC_NON_INDEFINI
		BEGIN
			SET @v_ata_validation = 1
			UPDATE CHARGE SET CHG_AVALIDER = @v_ata_validation WHERE CHG_ID = @v_chg_idcharge
			IF @@ERROR <> 0
				SET @v_retour = @CODE_KO_SQL
			ELSE
				SET @v_retour = @CODE_OK
		END
		ELSE
		BEGIN
			SET @v_ata_validation = 0
			SET @v_retour = @CODE_OK
		END
	END
	RETURN @v_retour

