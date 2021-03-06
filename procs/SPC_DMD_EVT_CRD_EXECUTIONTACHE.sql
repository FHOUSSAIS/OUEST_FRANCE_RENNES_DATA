SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

-- =============================================
-- Description:	Gestion de l'évènement Compte Rendu Exec Tache 
--				par le gestionnaire de demandes de Réorga de Stock
-- @v_ActionTache		: Action 
-- @v_IdMission			: Mission
-- @v_IdDemande			: Demande
-- @v_StatutPrimaire	: Statut primaire
-- @v_Description		: Description
-- @v_IdAgv				: AGV
-- @v_IdBobine			: Charge
-- @v_BaseExecSys		: Systeme
-- @v_BaseExecBase		: Base
-- @v_BaseExecSousBase	: Sous Base

-- =============================================
CREATE PROCEDURE [dbo].[SPC_DMD_EVT_CRD_EXECUTIONTACHE]
	--@v_AbonneEmetteur INT,
	@v_ActionTache INT,
	@v_IdMission INT,
	@v_IdDemande varchar(20),
	@v_StatutPrimaire TINYINT,
	@v_Description TINYINT,
	@v_IdAgv TINYINT,
	@v_IdBobine INT,
	@v_BaseExecSys BIGINT,
	@v_BaseExecBase BIGINT,
	@v_BaseExecSousBase BIGINT
AS
BEGIN
-- Déclaration des constantes
DECLARE	@ACT_PRISE TINYINT,
		@ACT_DEPOSE TINYINT,
		@EXEC_OK TINYINT,
		@EXEC_KO TINYINT,
		@CODE_OK TINYINT,
		@ETAT_DMD_ANNULEE TINYINT,
		@DESC_ETAT_ERREUREXECUTION INT,
		@DESC_ETAT_EXECMANUELLE INT,
		@A_VERIFIER TINYINT,
		@IDDEF_FP_DMD_REORGA TINYINT,
		@CATDEFDMD_REORGA TINYINT
		
-- Déclaration des variables
DECLARE @Retour INT,
		@InfoPlus VARCHAR(200),
		@BaseBobine VARCHAR(20)
		
DECLARE @v_transaction varchar(32),
		@v_local bit
		
-- Initialisation des constantes
SET @ACT_PRISE	= 2
SET @ACT_DEPOSE = 4
SET @EXEC_OK = 0
SET @EXEC_KO = 1
SET @CODE_OK = 0
SET @ETAT_DMD_ANNULEE	= 12
SET @DESC_ETAT_ERREUREXECUTION = 1
SET @DESC_ETAT_EXECMANUELLE = 4
SET @A_VERIFIER = 1

SET @IDDEF_FP_DMD_REORGA = 5
SET @CATDEFDMD_REORGA	= 5

-- Initialisation des variables
SET @Retour = @CODE_OK
SET @v_transaction = '[SPC_DMD_EVT_CRD_EXECUTIONTACHE]'

-- Gestion uniquement des demandes NOHAB
IF Exists (SELECT 1 FROM SPC_DMD_REORGA_STOCK_GENERAL WHERE SDG_IDDEMANDE = @v_IdDemande)
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Gestion des ouvertures de transactions
-----------------------------------------
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	
	-- Gestion de la prise KO
	IF @v_ActionTache = @ACT_PRISE AND @v_StatutPrimaire = @EXEC_KO
	BEGIN
		IF @v_description = @DESC_ETAT_ERREUREXECUTION
		BEGIN
			-- On met l'allée à vérifier
			IF @Retour = @CODE_OK 
			BEGIN
				SELECT @BaseBobine = ADR_ADRESSE FROM INT_ADRESSE
					WHERE ADR_IDSYSTEME = @v_BaseExecSys
						AND ADR_IDBASE = @v_BaseExecBase
						AND ADR_IDSOUSBASE = @v_BaseExecSousBase
				IF @BaseBobine LIKE '%ST_%'
					EXEC @Retour = dbo.INT_SETVERIFICATIONADRESSE @v_BaseExecSys, @v_BaseExecBase, @v_BaseExecSousBase, @A_VERIFIER
			END

			-- On monte un défaut Installation
			IF @Retour = @CODE_OK
			BEGIN
				SET @InfoPlus = 'Dmd;' + CONVERT(VARCHAR,@v_IdDemande)
				EXEC @Retour = SPC_DEF_MONTEE_DEFAUT @IDDEF_FP_DMD_REORGA, @CATDEFDMD_REORGA, @InfoPlus
			END
		END

		--Passage de la demande en annulée		
		exec SPC_DDG_MODIFIER_DEMANDE @v_IdDemande, @ETAT_DMD_ANNULEE, NULL, NULL

	END
END

-- Gestion des fermetures de transactions
-----------------------------------------
	IF @Retour <> @CODE_OK
	BEGIN
		IF @v_local = 1
			ROLLBACK TRAN @v_transaction
	END
	ELSE IF @v_local = 1
		COMMIT TRAN @v_transaction
	RETURN @Retour
END


