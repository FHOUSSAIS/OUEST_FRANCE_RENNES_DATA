SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Gestion de l'évènement Changement d'état Mission 
--				par le gestionnaire de demandes Réorga de Stock
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDG_EVT_CHGT_ETATMISSION]
	@v_IdMission INT,
	@v_IdDemande varchar(20),
	@v_EtatMission TINYINT,
	@v_CauseChgt TINYINT,
	@v_IdAgv INT,
	@v_IdBobine INT
AS
BEGIN
-- Déclaration des constantes
DECLARE @ETATMIS_ENCOURS TINYINT,
		@ETATMIS_STOPPEE TINYINT,
		@ETATMIS_ENATTENTE TINYINT,
		@CODE_OK TINYINT
DECLARE @ETAT_DMD_NOUVELLE		INT = 0
DECLARE @ETAT_DMD_EN_ATTENTE	INT = 1
DECLARE @ETAT_DMD_EN_COURS		INT = 2
DECLARE @ETAT_DMD_TERMINEE		INT = 3
DECLARE @ETAT_DMD_SUSPENDUE		INT = 11
DECLARE @ETAT_DMD_ANNULEE		INT = 12
		
DECLARE @ADRSYS_HORS_SYSTEME BIGINT,
		@ADRBASE_HORS_SYSTEME BIGINT,
		@ADRSOUSBASE_HORS_SYSTEME BIGINT
		
-- Déclaration des variables
DECLARE @Retour INT,
		@Origine VARCHAR(50),
		@InfoPlus VARCHAR(200),
		@ChaineTrace VARCHAR(200),
		@EtatDemande Tinyint

-- Initialisation des constantes
SET @ETATMIS_ENCOURS = 2
SET @ETATMIS_STOPPEE = 3
SET @ETATMIS_ENATTENTE = 1
SET @CODE_OK = 0

SET @ADRSYS_HORS_SYSTEME  = 65793
SET @ADRBASE_HORS_SYSTEME = 216178283966955777
SET @ADRSOUSBASE_HORS_SYSTEME = 65793

-- Initialisation des variables
SET @Retour = @CODE_OK

IF Exists (SELECT 1 FROM SPC_DMD_REORGA_STOCK_GENERAL WHERE SDG_IDDEMANDE = @v_IdDemande)
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Si c'est la première mission qui passe en cours on passe la demande en cours
	Select @EtatDemande = SPC_DMD_REORGA_STOCK_GENERAL.SDG_ETAT from SPC_DMD_REORGA_STOCK_GENERAL where SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDDEMANDE = @v_IdDemande
	
	IF @v_EtatMission = @ETATMIS_ENCOURS and @EtatDemande = @ETATMIS_ENATTENTE
		EXEC SPC_DDG_MODIFIER_DEMANDE @v_idDemande = @v_IdDemande, @v_etat = @ETAT_DMD_EN_COURS, @v_priorite = NULL, @v_nbRestant = NULL

	-- Si Mission passe dans l'état STOPPEE
	-- => Modification de l'état de la demande (EN CHEMIN -> STOPPEE)
	-- + Dépose Manuelle mission
	-- GESTION DU SHUTDOWN AGV
	IF @v_EtatMission = @ETATMIS_STOPPEE
		AND ((SELECT IAG_OPERATIONNEL FROM INT_AGV WHERE IAG_IDAGV = @v_IdAgv)='N')
	BEGIN
		Exec INT_SETVERIFICATIONADRESSE @ADRSYS_HORS_SYSTEME, @ADRBASE_HORS_SYSTEME, @ADRSOUSBASE_HORS_SYSTEME, 0
		
		-- Exécution Manuelle de la mission pour dépose bobine Hors Système	
		EXEC @Retour = INT_EXECUTEMANUELLEMISSION @v_IdMission, @ADRSYS_HORS_SYSTEME,
									@ADRBASE_HORS_SYSTEME, @ADRSOUSBASE_HORS_SYSTEME, NULL, 0
		
		If @Retour = @CODE_OK
			EXEC SPC_DDG_MODIFIER_DEMANDE @v_idDemande = @v_IdDemande, @v_etat = @ETAT_DMD_SUSPENDUE, @v_priorite = NULL, @v_nbRestant = NULL
									
		SET @ChaineTrace = 'excute manuel mission @retour=' + CONVERT(varchar,@Retour)
		EXEC INT_ADDTRACESPECIFIQUE 'SPC_DDG_EVT_CHANGEMENT_ETATMISSION','[DBGMIS]', @ChaineTrace
	END
END
	
END

