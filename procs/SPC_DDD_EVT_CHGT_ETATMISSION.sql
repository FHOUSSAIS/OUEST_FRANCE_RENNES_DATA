SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Gestion de l'évènement Changement d'état Mission 
--				par le gestionnaire de demandes Réorga de Stock
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDD_EVT_CHGT_ETATMISSION]
	@v_IdMission	INT,
	@v_IdDemande	varchar(20),
	@v_EtatMission	TINYINT,
	@v_CauseChgt	TINYINT,
	@v_IdAgv		INT,
	@v_IdBobine		INT
AS
BEGIN
-- Déclaration des constantes
DECLARE @ETATMIS_EN_COURS TINYINT = 2,
		@ETATMIS_STOPPEE TINYINT = 3,	
		@CODE_OK TINYINT = 0
		
DECLARE @ADRSYS_HORS_SYSTEME BIGINT,
		@ADRBASE_HORS_SYSTEME BIGINT,
		@ADRSOUSBASE_HORS_SYSTEME BIGINT
		
-- Déclaration des variables
DECLARE @Retour INT,
		@Origine VARCHAR(50),
		@InfoPlus VARCHAR(200),
		@ChaineTrace VARCHAR(200)


SET @ADRSYS_HORS_SYSTEME  = 65793
SET @ADRBASE_HORS_SYSTEME = 216178283966955777
SET @ADRSOUSBASE_HORS_SYSTEME = 65793

-- Initialisation des variables
SET @Retour = @CODE_OK

IF Exists (SELECT 1 FROM SPC_DMD_APPRO_DEMAC WHERE SDD_IDDEMANDE = @v_IdDemande)
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @v_EtatMission = @ETATMIS_EN_COURS
	BEGIN
		EXEC SPC_DDD_MODIFIER_DEMANDE @v_idDemande = @v_IdDemande,
									  @v_etat = @ETATMIS_EN_COURS

	END

	-- Si Mission passe dans l'état STOPPEE
	IF @v_EtatMission = @ETATMIS_STOPPEE
		AND ((SELECT IAG_OPERATIONNEL FROM INT_AGV WHERE IAG_IDAGV = @v_IdAgv)='N')
	BEGIN
		Exec INT_SETVERIFICATIONADRESSE @ADRSYS_HORS_SYSTEME, @ADRBASE_HORS_SYSTEME, @ADRSOUSBASE_HORS_SYSTEME, 0
		
		-- Exécution Manuelle de la mission pour dépose bobine Hors Système	
		EXEC @Retour = INT_EXECUTEMANUELLEMISSION @v_IdMission, @ADRSYS_HORS_SYSTEME,
									@ADRBASE_HORS_SYSTEME, @ADRSOUSBASE_HORS_SYSTEME, NULL, 0
									
		SET @ChaineTrace = 'excute manuel mission @retour=' + CONVERT(varchar,@Retour)
		EXEC INT_ADDTRACESPECIFIQUE 'SPC_DDD_EVT_CHANGEMENT_ETATMISSION','[DBGMIS]', @ChaineTrace
	END
END
	
END

