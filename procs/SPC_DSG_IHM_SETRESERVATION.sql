SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Réservation d'une allée par un paramètre défini
-- @v_SysAllee 
-- @v_BaseAllee 
-- @v_SousBaseAllee  : Clé d'adressage
-- @IdLaize  : Laize
-- @IdDiametre : Dimaètre
-- @IdFournisseur : Fournisseur
-- @IdGrammage : Grammage
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DSG_IHM_SETRESERVATION]
	@v_SysAllee BIGINT,
	@v_BaseAllee BIGINT,
	@v_SousBaseAllee BIGINT,
	@IdLaize INT = NULL,
	@IdDiametre INT = NULL,
	@IdFournisseur INT = NULL,
	@IdGrammage INT = NULL
AS
BEGIN
-- Déclaration des constantes
-----------------------------
DECLARE @CODE_OK SMALLINT
DECLARE @CODE_KO_ALLEE_NONVIDE SMALLINT
DECLARE @CODE_KO_ALLEE_MISSIONENCOURS SMALLINT

DECLARE @ALLEE_VIDE TINYINT
DECLARE @ZONE_STOCK_B VARCHAR(20),
		@ETATTAC_ENATTENTE TINYINT,
		@ETATTAC_ENCOURS TINYINT

-- Déclaration de variables
---------------------------
DECLARE @v_transaction varchar(32),
		@v_local bit,
		@retour INT,
		@ChaineTrace varchar(200),
		@EtatAllee TINYINT,
		@CodeAllee VARCHAR(20),
		@AdrAllee TINYINT,
		@CodeGrammage NUMERIC(5,2)

-- Initialisation des constantes
--------------------------------
SET @CODE_KO_ALLEE_NONVIDE = -1399
SET @CODE_KO_ALLEE_MISSIONENCOURS = -1417
SET @CODE_OK = 0

SET @ALLEE_VIDE = 1
SET @ZONE_STOCK_B = 'ST_B'
SET @ETATTAC_ENATTENTE = 1
SET @ETATTAC_ENCOURS = 2

-- Initialisation des variables
-------------------------------
SET @retour = @CODE_OK
set @v_transaction = 'SPC_DSG_IHM_SETRESERVATION'

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		SET @ChaineTrace = '@v_SysAllee = ' +convert(varchar,(ISNULL(@v_SysAllee, '-1')))
						+' ,@v_BaseAllee = ' +convert(varchar,(ISNULL(@v_BaseAllee, '-1')))
						+' ,@v_SousBaseAllee = ' +convert(varchar,(ISNULL(@v_SousBaseAllee, '-1')))
						+' ,@IdLaize = ' +convert(varchar,(ISNULL(@IdLaize, '-1')))
						+' ,@IdDiametre = ' +convert(varchar,(ISNULL(@IdDiametre, '-1')))
						+' ,@IdFournisseur = ' +convert(varchar,(ISNULL(@IdFournisseur, '-1')))
						+' ,@IdGrammage = ' +convert(varchar,(ISNULL(@IdGrammage, '-1')))						
		EXEC INT_ADDTRACESPECIFIQUE @v_transaction, 'DEBUG', @ChaineTrace


-- Vérification des interdictions : allée doit être vide
	SELECT @EtatAllee = ADR_IDETAT_OCCUPATION
		FROM INT_ADRESSE
	WHERE ADR_IDSYSTEME = @v_SysAllee
			AND ADR_IDBASE = @v_BaseAllee
			AND ADR_IDSOUSBASE = @v_SousBaseAllee
	IF @EtatAllee <> @ALLEE_VIDE
		SET @retour = @CODE_KO_ALLEE_NONVIDE
			
-- Vérification des interdictions : l'allée ne doit pas être contenu dans une mission
	IF @retour = @CODE_OK
	BEGIN
		IF EXISTS (SELECT 1 FROM INT_TACHE_MISSION
					WHERE TAC_IDSYSTEMEEXECUTION = @v_SysAllee AND TAC_IDBASEEXECUTION = @v_BaseAllee AND TAC_IDSOUSBASEEXECUTION = @v_SousBaseAllee
							AND ((TAC_IDACTION = 4 AND TAC_IDETATTACHE IN (@ETATTAC_ENATTENTE, @ETATTAC_ENCOURS))
								 OR (TAC_IDACTION = 2 AND TAC_IDETATTACHE = @ETATTAC_ENCOURS)))
			SET @retour = @CODE_KO_ALLEE_MISSIONENCOURS
	END

-- Gestion des ouvertures de transactions
-----------------------------------------
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END

-----------------------------------------
--         GESTION PAR LA LAIZE        --
-----------------------------------------
IF @Idlaize <> -1
BEGIN
	IF @retour = @CODE_OK
	BEGIN
		-- Création de l'enregistrement s'il s'agit de la 1ère réservation
		IF not Exists (SELECT 1 FROM SPC_ADRESSE_STOCK_GENERAL WHERE SAG_IDSYSTEME = @v_SysAllee
				AND SAG_IDBASE = @v_BaseAllee
				AND SAG_IDSOUSBASE = @v_SousBaseAllee)
		BEGIN
			INSERT INTO SPC_ADRESSE_STOCK_GENERAL
				VALUES (@v_SysAllee, @v_BaseAllee, @v_SousBaseAllee,
					NULL, NULL, @IdLaize, NULL, 0 )
		END ELSE
		BEGIN
			-- Mise à jour de la bobine si l'enregistrement existe déjà	
			UPDATE SPC_ADRESSE_STOCK_GENERAL 
				SET SAG_LAIZE = @IdLaize
			WHERE SAG_IDSYSTEME = @v_SysAllee
				AND SAG_IDBASE = @v_BaseAllee
				AND SAG_IDSOUSBASE = @v_SousBaseAllee
		END
		SET @retour = @@ERROR
	END

	-- Ajout d'une trace de suivi
	IF @retour = @CODE_OK
	BEGIN
		IF @IdLaize IS NULL
			SET @ChaineTrace = 'Annulation Réservation Laize, Allée ' + (SELECT ADr_ADRESSE FROM INT_ADRESSE WHERE ADR_IDSYSTEME=@v_SysAllee AND ADR_IDBASE=@v_BaseAllee AND ADR_IDSOUSBASE=@v_SousBaseAllee)
		ELSE
			SET @ChaineTrace = 'Réservation Laize('+convert(varchar,(SELECT SCL_IDTRADUCTION FROM SPC_CHG_LAIZE WHERE SCL_LAIZE=@IdLaize))
						+'), Allée ' + (SELECT ADr_ADRESSE FROM INT_ADRESSE WHERE ADR_IDSYSTEME=@v_SysAllee AND ADR_IDBASE=@v_BaseAllee AND ADR_IDSOUSBASE=@v_SousBaseAllee)
		EXEC INT_ADDTRACESPECIFIQUE '[IHM]', '[TRCSTK]', @ChaineTrace
	END

END


-----------------------------------------
--        GESTION PAR LE DIAMETRE      --
-----------------------------------------
IF @IdDiametre <> -1
BEGIN
	IF @retour = @CODE_OK
	BEGIN

		-- Création de l'enregistrement s'il s'agit de la 1ère réservation
		IF not Exists (SELECT 1 FROM SPC_ADRESSE_STOCK_GENERAL WHERE SAG_IDSYSTEME = @v_SysAllee
				AND SAG_IDBASE = @v_BaseAllee
				AND SAG_IDSOUSBASE = @v_SousBaseAllee)
		BEGIN
			INSERT INTO SPC_ADRESSE_STOCK_GENERAL
				VALUES (@v_SysAllee, @v_BaseAllee, @v_SousBaseAllee,
					NULL, NULL, NULL, @IdDiametre, 0 )
		END ELSE
		BEGIN
			-- Mise à jour de la bobine si l'enregistrement existe déjà	
			UPDATE SPC_ADRESSE_STOCK_GENERAL 
				SET SAG_DIAMETRE = @IdDiametre
			WHERE SAG_IDSYSTEME = @v_SysAllee
				AND SAG_IDBASE = @v_BaseAllee
				AND SAG_IDSOUSBASE = @v_SousBaseAllee
		END
		SET @retour = @@ERROR
	END

	-- Ajout d'une trace de suivi
	IF @retour = @CODE_OK
	BEGIN
		IF @IdDiametre IS NULL
			SET @ChaineTrace = 'Annulation Réservation Diamètre, Allée ' + (SELECT ADr_ADRESSE FROM INT_ADRESSE WHERE ADR_IDSYSTEME=@v_SysAllee AND ADR_IDBASE=@v_BaseAllee AND ADR_IDSOUSBASE=@v_SousBaseAllee)
		ELSE
			SET @ChaineTrace = 'Réservation Diamètre('+convert(varchar,(SELECT SCD_DIAMETRE FROM SPC_CHG_DIAMETRE WHERE SCD_DIAMETRE=@IdDiametre))  -- ???
						+'), Allée ' + (SELECT ADr_ADRESSE FROM INT_ADRESSE WHERE ADR_IDSYSTEME=@v_SysAllee AND ADR_IDBASE=@v_BaseAllee AND ADR_IDSOUSBASE=@v_SousBaseAllee)
		EXEC INT_ADDTRACESPECIFIQUE '[IHM]', '[TRCSTK]', @ChaineTrace
	END
END

-----------------------------------------
--      GESTION PAR LE FOURNISSEUR     --
-----------------------------------------
IF @IdFournisseur <> -1
BEGIN
	IF @retour = @CODE_OK
	BEGIN
		-- Création de l'enregistrement s'il s'agit de la 1ère réservation
		IF not Exists (SELECT 1 FROM SPC_ADRESSE_STOCK_GENERAL WHERE SAG_IDSYSTEME = @v_SysAllee
				AND SAG_IDBASE = @v_BaseAllee
				AND SAG_IDSOUSBASE = @v_SousBaseAllee)
		BEGIN
			INSERT INTO SPC_ADRESSE_STOCK_GENERAL
				VALUES (@v_SysAllee, @v_BaseAllee, @v_SousBaseAllee,
					NULL, @IdFournisseur, NULL, NULL, 0 )
		END ELSE
		BEGIN
			-- Mise à jour de la bobine si l'enregistrement existe déjà	
			UPDATE SPC_ADRESSE_STOCK_GENERAL 
				SET SAG_IDFOURNISSEUR = @IdFournisseur
			WHERE SAG_IDSYSTEME = @v_SysAllee
				AND SAG_IDBASE = @v_BaseAllee
				AND SAG_IDSOUSBASE = @v_SousBaseAllee
		END
		SET @retour = @@ERROR
	END
	
	-- Ajout d'une trace de suivi
	IF @retour = @CODE_OK
	BEGIN
		IF @IdFournisseur IS NULL
			SET @ChaineTrace = 'Annulation Réservation Fournisseur, Allée ' + (SELECT ADr_ADRESSE FROM INT_ADRESSE WHERE ADR_IDSYSTEME=@v_SysAllee AND ADR_IDBASE=@v_BaseAllee AND ADR_IDSOUSBASE=@v_SousBaseAllee)
		ELSE
			SET @ChaineTrace = 'Réservation Fournisseur('+dbo.INT_GETLIBELLE((SELECT SCF_IDTRADUCTION_PAPETERIE FROM SPC_CHG_FOURNISSEUR WHERE SCF_IDFOURNISSEUR=@IdFournisseur),'FRA')
						+'), Allée ' + (SELECT ADr_ADRESSE FROM INT_ADRESSE WHERE ADR_IDSYSTEME=@v_SysAllee AND ADR_IDBASE=@v_BaseAllee AND ADR_IDSOUSBASE=@v_SousBaseAllee)
		EXEC INT_ADDTRACESPECIFIQUE '[IHM]', '[TRCSTK]', @ChaineTrace
	END
END
-----------------------------------------
--        GESTION PAR LE GRAMMAGE      --
-----------------------------------------
IF @IdGrammage <> -1
BEGIN
	SELECT @CodeGrammage = SCG_GRAMMAGE from SPC_CHG_GRAMMAGE where SCG_CODE = @IdGrammage

	IF @retour = @CODE_OK
	BEGIN
		-- Création de l'enregistrement s'il s'agit de la 1ère réservation
		IF not Exists (SELECT 1 FROM SPC_ADRESSE_STOCK_GENERAL WHERE SAG_IDSYSTEME = @v_SysAllee
				AND SAG_IDBASE = @v_BaseAllee
				AND SAG_IDSOUSBASE = @v_SousBaseAllee)
		BEGIN
			INSERT INTO SPC_ADRESSE_STOCK_GENERAL
				VALUES (@v_SysAllee, @v_BaseAllee, @v_SousBaseAllee,
					@CodeGrammage, NULL, NULL, NULL, 0 )
		END ELSE
		BEGIN
			-- Mise à jour de la bobine si l'enregistrement existe déjà	
			UPDATE SPC_ADRESSE_STOCK_GENERAL 
				SET SAG_GRAMMAGE = @CodeGrammage
			WHERE SAG_IDSYSTEME = @v_SysAllee
				AND SAG_IDBASE = @v_BaseAllee
				AND SAG_IDSOUSBASE = @v_SousBaseAllee
		END
		SET @retour = @@ERROR
	END
	
	-- Ajout d'une trace de suivi
	IF @retour = @CODE_OK
	BEGIN
		IF @CodeGrammage IS NULL
			SET @ChaineTrace = 'Annulation Réservation Grammage, Allée ' + (SELECT ADr_ADRESSE FROM INT_ADRESSE WHERE ADR_IDSYSTEME=@v_SysAllee AND ADR_IDBASE=@v_BaseAllee AND ADR_IDSOUSBASE=@v_SousBaseAllee)
		ELSE
			SET @ChaineTrace = 'Réservation Grammage('+CONVERT(varchar,@CodeGrammage)--(SELECT SGR_LIBELLE FROM SPC_CHG_GRAMMAGE WHERE SGR_IDGRAMMAGE=@CodeGrammage) FST-0710-01
						+'), Allée ' + (SELECT ADr_ADRESSE FROM INT_ADRESSE WHERE ADR_IDSYSTEME=@v_SysAllee AND ADR_IDBASE=@v_BaseAllee AND ADR_IDSOUSBASE=@v_SousBaseAllee)
		EXEC INT_ADDTRACESPECIFIQUE '[IHM]', '[TRCSTK]', @ChaineTrace
	END
END

IF @IdLaize IS NULL and
	@IdDiametre IS NULL and
	@IdFournisseur IS NULL and
	@IdGrammage IS NULL
BEGIN
		-- Création de l'enregistrement s'il s'agit de la 1ère réservation
		IF not Exists (SELECT 1 FROM SPC_ADRESSE_STOCK_GENERAL WHERE SAG_IDSYSTEME = @v_SysAllee
				AND SAG_IDBASE = @v_BaseAllee
				AND SAG_IDSOUSBASE = @v_SousBaseAllee)
		BEGIN
			INSERT INTO SPC_ADRESSE_STOCK_GENERAL
				VALUES (@v_SysAllee, @v_BaseAllee, @v_SousBaseAllee,
					NULL, NULL, NULL, NULL, 0 )
		END ELSE
		BEGIN
			-- Mise à jour de la bobine si l'enregistrement existe déjà	
			UPDATE SPC_ADRESSE_STOCK_GENERAL 
				SET SAG_LAIZE = NULL, SAG_DIAMETRE = NULL,SAG_IDFOURNISSEUR = NULL,SAG_GRAMMAGE = NULL
			WHERE SAG_IDSYSTEME = @v_SysAllee
				AND SAG_IDBASE = @v_BaseAllee
				AND SAG_IDSOUSBASE = @v_SousBaseAllee
		END
		SET @retour = @@ERROR

END


-- Gestion des fermetures de transactions
-----------------------------------------
	IF @retour <> @CODE_OK
	BEGIN
		IF @v_local = 1
			ROLLBACK TRAN @v_transaction
	END
	ELSE IF @v_local = 1
		COMMIT TRAN @v_transaction
	RETURN @retour

END
