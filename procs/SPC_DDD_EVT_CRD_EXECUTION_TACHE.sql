SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Traitement d'Evenement de compte rendu d'éxecution de tâche
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDD_EVT_CRD_EXECUTION_TACHE]
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
		@CODE_OK TINYINT = 0
DECLARE @PAS_AFFINAGE TINYINT = 0,
		@AFFINAGE_EXECUTION TINYINT = 2,
		@PRISE_CENTREE TINYINT = 1
		
-- Déclaration des variables
DECLARE @retour INT
		
DECLARE @procStock varchar(32),
		@v_local bit,
		@ChaineTrace VARCHAR(200)

DECLARE @ETAT_DMD_NOUVELLE		INT = 0
DECLARE @ETAT_DMD_EN_ATTENTE	INT = 1
DECLARE @ETAT_DMD_EN_COURS		INT = 2
DECLARE @ETAT_DMD_TERMINEE		INT = 3
DECLARE @ETAT_DMD_SUSPENDUE		INT = 11
DECLARE @ETAT_DMD_ANNULEE		INT = 12

DECLARE @DESC_ETAT_ERREUREXECUTION INT = 1
DECLARE	@DESC_ETAT_EXECMANUELLE INT = 4

-- Initialisation des variables
SET @retour = @CODE_OK
SET @procStock = 'SPC_DDD_EVT_CRD_EXECUTION_TACHE'


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
		BEGIN TRAN @procStock
	END
	
if exists( select 1 from SPC_DMD_APPRO_DEMAC where SDD_IDDEMANDE = @v_IdDemande )
begin
	SET @ChaineTrace = '@v_IdMission='+CONVERT(VARCHAR,isnull(@v_IdMission,-1)) 
					+ ',@v_ActionTache=' + CONVERT(varchar,isnull(@v_ActionTache,-1))
					+ ',@v_IdAgv=' + CONVERT(varchar,isnull(@v_IdAgv,-1))
					+ ',@v_IdBobine=' + CONVERT(varchar,isnull(@v_IdBobine,-1))
					+ ',@v_StatutPrimaire=' + CONVERT(varchar,isnull(@v_StatutPrimaire,-1))
					+ ',@v_Description=' + CONVERT(varchar,isnull(@v_Description,-1))
					+ ',@v_IdDemande=' + CONVERT(varchar,isnull(@v_IdDemande,-1))
	EXEC dbo.INT_ADDTRACESPECIFIQUE @procStock, '[DBGMIS]', @ChaineTrace

	-- Gestion de la Prise OK
	--------------------------
	IF @v_ActionTache = @ACT_DEPOSE AND @v_StatutPrimaire = @EXEC_OK 
		AND @v_description <> @DESC_ETAT_EXECMANUELLE
	BEGIN
		EXEC SPC_DDD_MODIFIER_DEMANDE @v_idDemande = @v_IdDemande,
									  @v_idBobine = @v_IdBobine
	END

	-- Gestion de la dépose OK
	--------------------------
	IF @v_ActionTache = @ACT_DEPOSE AND @v_StatutPrimaire = @EXEC_OK 
		AND @v_description <> @DESC_ETAT_EXECMANUELLE
	BEGIN
		EXEC SPC_DDD_MODIFIER_DEMANDE	@v_idDemande = @v_IdDemande,
										@v_etat = @ETAT_DMD_TERMINEE
	END

	-- Gestion de la prise KO
	--------------------------
	IF @v_ActionTache = @ACT_PRISE AND @v_StatutPrimaire = @EXEC_KO
		AND @v_description = @DESC_ETAT_ERREUREXECUTION
	BEGIN
			EXEC @retour = SPC_DDG_MODIFIER_DEMANDE	@v_idDemande = @v_IdDemande,
													@v_etat = @ETAT_DMD_SUSPENDUE

	END

	-- Gestion de la Dépose manuelle
	--------------------------
	IF @v_ActionTache = @ACT_DEPOSE AND @v_StatutPrimaire = @EXEC_OK 
		AND @v_description = @DESC_ETAT_EXECMANUELLE
	BEGIN
		EXEC SPC_DDD_MODIFIER_DEMANDE @v_idDemande = @v_IdDemande,
										@v_etat = @ETAT_DMD_SUSPENDUE
	END
END
-- Gestion des fermetures de transactions
-----------------------------------------
IF @retour <> @CODE_OK
BEGIN
	IF @v_local = 1
		ROLLBACK TRAN @procStock
END
ELSE IF @v_local = 1
	COMMIT TRAN @procStock
RETURN @retour
END


