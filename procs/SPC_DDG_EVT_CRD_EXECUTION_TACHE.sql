SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

-- =============================================
-- Description:	Gestion de l'évènement Compte Rendu Exec Tache 
--				par le gestionnaire de demandes de Réorga de Stock
--  @v_AbonneEmetteur 
--	@v_ActionTache 
--	@v_IdMission
--	@v_IdDemande 
--	@v_StatutPrimaire 
--	@v_Description
--	@v_IdAgv
--	@v_IdBobine
--	@v_BaseExecSys
--	@v_BaseExecBase
--	@v_BaseExecSousBase
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDG_EVT_CRD_EXECUTION_TACHE]
	@v_AbonneEmetteur INT,
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
DECLARE @ACT_PRISE TINYINT = 2,
		@ACT_DEPOSE TINYINT = 4,
		@EXEC_OK TINYINT = 0,
		@EXEC_KO TINYINT = 1,
		@CODE_OK TINYINT = 0,
		@DESC_ETAT_ERREUREXECUTION INT = 1,
		@DESC_ETAT_EXECMANUELLE INT = 4,
		@A_VERIFIER TINYINT = 1
		
DECLARE @ETAT_DMD_NOUVELLE		INT = 0
DECLARE @ETAT_DMD_EN_ATTENTE	INT = 1
DECLARE @ETAT_DMD_EN_COURS		INT = 2
DECLARE @ETAT_DMD_TERMINEE		INT = 3
DECLARE @ETAT_DMD_SUSPENDUE		INT = 11
DECLARE @ETAT_DMD_ANNULEE		INT = 12

-- Déclaration des variables
DECLARE @Retour INT,
		@InfoPlus VARCHAR(200),
		@MagasinBobine INT,
		@IdTypeMagasinBobine INT,
		@NbBobinesRestant INT
		
DECLARE @v_transaction varchar(32),
		@v_local bit

-- Initialisation des variables
SET @Retour = @CODE_OK
SET @v_transaction = 'SPC_DDG_EVT_CRD_EXECUTION_TACHE'

-- Gestion uniquement des demandes NOHAB
IF Exists (SELECT 1 FROM SPC_DMD_REORGA_STOCK_GENERAL WHERE SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDDEMANDE = @v_IdDemande)
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

IF Exists (SELECT 1 FROM SPC_DMD_REORGA_STOCK_GENERAL WHERE SDG_IDDEMANDE = @v_IdDemande)
BEGIN	
	-- Gestion de la prise OK
	--------------------------
	IF @v_ActionTache = @ACT_PRISE AND @v_StatutPrimaire = @EXEC_OK 
		AND @v_description <> @DESC_ETAT_EXECMANUELLE
	BEGIN
		-- Nb restant -1
		SELECT @NbBobinesRestant = SPC_DMD_REORGA_STOCK_GENERAL.SDG_NBRESTANT - 1 from SPC_DMD_REORGA_STOCK_GENERAL where SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDDEMANDE = @v_IdDemande
		
		IF @NbBobinesRestant > 0
			EXEC @retour = SPC_DDG_MODIFIER_DEMANDE @v_idDemande = @v_IdDemande , @v_nbRestant = @NbBobinesRestant
		ELSE
			EXEC @retour = SPC_DDG_MODIFIER_DEMANDE @v_idDemande = @v_IdDemande ,@v_etat = @ETAT_DMD_TERMINEE, @v_nbRestant = 0
	END

END

	-- Gestion de la prise KO
	IF @v_ActionTache = @ACT_PRISE AND @v_StatutPrimaire = @EXEC_KO
	BEGIN
		IF @v_description = @DESC_ETAT_ERREUREXECUTION
		BEGIN
			-- On met l'allée à vérifier
			IF @Retour = @CODE_OK 
			BEGIN
				SELECT @MagasinBobine = INT_ADRESSE.ADR_MAGASIN,@IdTypeMagasinBobine = INT_ADRESSE.ADR_IDTYPEMAGASIN  FROM INT_ADRESSE
					WHERE ADR_IDSYSTEME = @v_BaseExecSys
						AND ADR_IDBASE = @v_BaseExecBase
						AND ADR_IDSOUSBASE = @v_BaseExecSousBase
				IF @MagasinBobine = 2 and  @IdTypeMagasinBobine = 3
					EXEC @Retour = dbo.INT_SETVERIFICATIONADRESSE @v_BaseExecSys, @v_BaseExecBase, @v_BaseExecSousBase, @A_VERIFIER
				
				EXEC @retour = SPC_DDG_MODIFIER_DEMANDE @v_idDemande = @v_IdDemande ,@v_etat = @ETAT_DMD_ANNULEE
			END
		END
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


