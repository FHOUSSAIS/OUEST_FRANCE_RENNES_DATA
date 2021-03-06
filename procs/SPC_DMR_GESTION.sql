SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Gérer les Demandes de Mouvements TRR
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DMR_GESTION]
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @ETAT_DMD_NOUVELLE		INT = 0
DECLARE @ETAT_DMD_EN_ATTENTE	INT = 1
DECLARE @ETAT_DMD_EN_COURS		INT = 2
DECLARE @ETAT_DMD_TERMINEE		INT = 3
DECLARE @ETAT_DMD_SUSPENDUE		INT = 11
DECLARE @ETAT_DMD_ANNULEE		INT = 12
DECLARE @ETAT_DMD_REFUSEE		INT = 13

DECLARE @TRR_ACTION_MOUVEMENT INT = 1
DECLARE @TRR_ACTION_PRISE INT = 3
DECLARE @TRR_ACTION_DEPOSE INT = 5

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Mouvement TRR'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @dmd_idDemande VARCHAR(20)
DECLARE @dmd_etat INT
DECLARE @dmd_positionXPrise INT
DECLARE @dmd_positionYPrise INT
DECLARE @dmd_positionZPrise INT
DECLARE @dmd_positionXDepose INT
DECLARE @dmd_positionYDepose INT
DECLARE @dmd_positionZDepose INT
DECLARE @dmd_complement INT

SET @trace = 'Gestion des demandes'
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

/*---------------------------------------------------
	Gestion des Nouvelles de Demande
	Création des actions associées
---------------------------------------------------*/
	SELECT TOP 1
		@dmd_idDemande = dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDDEMANDE,
		@dmd_positionXPrise = POSITION_PRISE.SAA_POSITIONX,
		@dmd_positionYPrise = POSITION_PRISE.SAA_POSITIONY,
		@dmd_positionZPrise = POSITION_PRISE.SAA_POSITIONZ,
		@dmd_positionXDepose = POSITION_DEPOSE.SAA_POSITIONX,
		@dmd_positionYDepose = POSITION_DEPOSE.SAA_POSITIONY,
		@dmd_positionZDepose = POSITION_DEPOSE.SAA_POSITIONZ,
		@dmd_complement = dbo.SPC_CHG_LAIZE.SCL_INFO_TRR
	FROM dbo.SPC_DMD_MOUVEMENT_TRR
	JOIN dbo.SPC_TRR_ASSOCIATION_ADRESSE POSITION_PRISE
		ON dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSYSTEME_PRISE = POSITION_PRISE.SAA_IDSYSTEME
		AND dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDBASE_PRISE = POSITION_PRISE.SAA_IDBASE
		AND dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSOUSBASE_PRISE = POSITION_PRISE.SAA_IDSOUSBASE
	JOIN dbo.SPC_TRR_ASSOCIATION_ADRESSE POSITION_DEPOSE
		ON dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSYSTEME_DEPOSE = POSITION_DEPOSE.SAA_IDSYSTEME
		AND dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDBASE_DEPOSE = POSITION_DEPOSE.SAA_IDBASE
		AND dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSOUSBASE_DEPOSE = POSITION_DEPOSE.SAA_IDSOUSBASE
	JOIN dbo.INT_CHARGE_VIVANTE
		ON dbo.INT_CHARGE_VIVANTE.CHG_IDSYSTEME = dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSYSTEME_PRISE
		AND dbo.INT_CHARGE_VIVANTE.CHG_IDBASE = dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDBASE_PRISE
		AND dbo.INT_CHARGE_VIVANTE.CHG_IDSOUSBASE = dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSOUSBASE_PRISE
	JOIN dbo.SPC_CHARGE_BOBINE ON dbo.INT_CHARGE_VIVANTE.CHG_IDCHARGE = dbo.SPC_CHARGE_BOBINE.SCB_IDCHARGE
	JOIN dbo.SPC_CHG_LAIZE on dbo.SPC_CHARGE_BOBINE.SCB_LAIZE = dbo.SPC_CHG_LAIZE.SCL_LAIZE 
	WHERE dbo.SPC_DMD_MOUVEMENT_TRR.SDM_ETAT = 0
	ORDER BY dbo.SPC_DMD_MOUVEMENT_TRR.SDM_PRIORITE DESC, dbo.SPC_DMD_MOUVEMENT_TRR.SDM_DATE


	SET @trace = 'Traitement Nouvelle Demande ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
			+ ', @dmd_positionXPrise = ' + ISNULL(CONVERT(VARCHAR, @dmd_positionXPrise), 'NULL')	
			+ ', @dmd_positionYPrise = ' + ISNULL(CONVERT(VARCHAR, @dmd_positionYPrise), 'NULL')	
			+ ', @dmd_positionZPrise = ' + ISNULL(CONVERT(VARCHAR, @dmd_positionZPrise), 'NULL')	
			+ ', @dmd_positionXDepose = ' + ISNULL(CONVERT(VARCHAR, @dmd_positionXDepose), 'NULL')	
			+ ', @dmd_positionYDepose = ' + ISNULL(CONVERT(VARCHAR, @dmd_positionYDepose), 'NULL')	
			+ ', @dmd_positionZDepose = ' + ISNULL(CONVERT(VARCHAR, @dmd_positionZDepose), 'NULL')	
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'DEBUG',
								@v_trace = @trace

	-- Création Action Mouvement Prise
	INSERT INTO dbo.SPC_TRR_LISTEACTION VALUES ( 1, @dmd_idDemande, @TRR_ACTION_MOUVEMENT, @dmd_positionXPrise, @dmd_positionYPrise, @dmd_positionZPrise, NULL, 1, GETDATE(), @ETAT_DMD_EN_ATTENTE, NULL )
	select * FROM dbo.SPC_TRR_LISTEACTION 
	-- Création Action Prise
	INSERT INTO dbo.SPC_TRR_LISTEACTION VALUES ( 1, @dmd_idDemande, @TRR_ACTION_PRISE, @dmd_positionXPrise, @dmd_positionYPrise, @dmd_positionZPrise, NULL, 1, GETDATE(), @ETAT_DMD_EN_ATTENTE, NULL )
	-- Création Action Mouvement Dépose

	-- Création Action Dépose


	
	IF (@retour <> @CODE_OK)
	BEGIN
		SET @trace = 'Erreur a la création de la demande Appro Démac ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
		SET @dmd_etat = @ETAT_DMD_REFUSEE
	END
	ELSE
	BEGIN
		SET @trace = 'La demande Appro Démac a été créée ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace
		SET @dmd_etat = @ETAT_DMD_EN_ATTENTE
	END

	EXEC @retour = dbo.SPC_DRR_MODIFIER_DEMANDE @v_idDemande = @dmd_idDemande, @v_etat = @dmd_etat

	IF (@retour <> @CODE_OK)
	BEGIN
		SET @trace = 'Erreur a la mise à jour de la demande' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
	END
	ELSE
	BEGIN
		SET @trace = 'La demande a été mise à jour ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace
	END


	

RETURN @retour
END

