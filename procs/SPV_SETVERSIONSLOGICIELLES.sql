SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: SPV_SETVERSIONSLOGICIELLES
-- Paramètre d'entrée	: @v_nomProcess varchar(80) : nom du process que l'on trace,
--					      @v_nomMachine varchar(80) : machine hote ou le process s'execute,
--					      @v_versionAgv varchar(80) : version du paquet agv,
--					      @v_versionLogisticManager varchar(80) : version du paquet traffic_manager
--					      @v_versionTools varchar(80) : version du paquet tools,
--					      @v_versionTrack varchar(80) : version du paquet track,
--					      @v_versionTrafficManager varchar(80) : version du paquet traffic_manager,
--					      @v_versionCircuit varchar(80) : version du circuit utilise par le process
-- Paramètres de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
-- Descriptif		: remplir la table VERSIONS_LOGICIELLES
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_SETVERSIONSLOGICIELLES]
	@v_nomProcess varchar(80),
	@v_nomMachine varchar(80),
	@v_versionAgv varchar(80),
	@v_versionLogisticManager varchar(80),
	@v_versionTools varchar(80),
	@v_versionTrack varchar(80),
	@v_versionTrafficManager varchar(80),
	@v_versionCircuit varchar(80)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_retour int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK int,
	@CODE_KO int

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1

-- Initialisation de la variable de retour
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	BEGIN TRAN

	--S'il y a deja, on update
	IF EXISTS (SELECT 1 FROM VERSIONS_LOGICIELLES WHERE VLO_NOM_PROCESS=@v_nomProcess AND VLO_NOM_MACHINE=@v_nomMachine)
	BEGIN
	UPDATE VERSIONS_LOGICIELLES SET
		VLO_VERSION_AGV = @v_versionAgv,
		VLO_VERSION_LOGISTIC_MANAGER = @v_versionLogisticManager,
		VLO_VERSION_TOOLS = @v_versionTools,
		VLO_VERSION_TRACK = @v_versionTrack,
		VLO_VERSION_TRAFFIC_MANAGER = @v_versionTrafficManager,
		VLO_VERSION_CIRCUIT = @v_versionCircuit,
		VLO_DATE_DEMARRAGE = GETDATE()
    WHERE VLO_NOM_PROCESS=@v_nomProcess AND VLO_NOM_MACHINE=@v_nomMachine
	END
	ELSE
	--sinon, on insert
	BEGIN
		INSERT INTO VERSIONS_LOGICIELLES
				(VLO_NOM_PROCESS, VLO_NOM_MACHINE,
				 VLO_VERSION_AGV, VLO_VERSION_LOGISTIC_MANAGER, VLO_VERSION_TOOLS, VLO_VERSION_TRACK, VLO_VERSION_TRAFFIC_MANAGER,
				 VLO_VERSION_CIRCUIT, VLO_DATE_DEMARRAGE)
        VALUES  (@v_nomProcess,   @v_nomMachine, 
				 @v_versionAgv,   @v_versionLogisticManager,      @v_versionTools,   @v_versionTrack,   @v_versionTrafficManager,
				 @v_versionCircuit,   GETDATE());
	END
	
	SELECT @v_error = @@ERROR
	IF @v_error = 0
		SELECT @v_retour = @CODE_OK
	ELSE
		SELECT @v_retour = @CODE_KO
	
	IF @v_retour <> @CODE_OK
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_retour


