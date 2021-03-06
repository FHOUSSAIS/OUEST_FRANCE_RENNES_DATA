SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

CREATE  PROCEDURE [dbo].[INT_CREATEMISSION]
	@v_mis_idmission int out,
	@v_mis_demande varchar(20) = NULL,
	@v_mis_priorite int = 0,
	@v_mis_dateecheance datetime = NULL,
	@v_mis_idcharge int = NULL,
	@v_mis_idagv tinyint = NULL,
	@v_mis_idlegende int = NULL,
	@v_mis_decharge bit = 0,
	@v_mis_idtypeagv tinyint = NULL,
	@v_mis_idtypeoutil tinyint = NULL
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
	@v_retour int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCONNU tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_CHARGE tinyint

-- Déclaration des constantes de types de missions
DECLARE 
	@TYPE_NONDEFINI tinyint   

-- Déclaration des constantes d'états de missions
DECLARE
	@ETAT_ENATTENTE tinyint

-- Déclaration des constantes de familles
DECLARE
	@CRIT_MISSION tinyint

-- Déclaration des constantes de catégories
DECLARE
	@CATE_MISSION tinyint

-- Déclaration des constantes de légende
DECLARE
	@LEGE_MISSION smallint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_INCONNU = 7
	SELECT @CODE_KO_SQL = 13
	SELECT @CODE_KO_CHARGE = 19
	SELECT @TYPE_NONDEFINI = 0
	SELECT @ETAT_ENATTENTE = 1
	SELECT @CRIT_MISSION = 0
	SELECT @CATE_MISSION = 12
	SELECT @LEGE_MISSION = 7

-- Initialisation des variables
	SELECT @v_transaction = 'CREATEMISSION'
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de la charge
	IF ((@v_mis_idcharge IS NULL) OR (@v_mis_idcharge IS NOT NULL AND EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE = @v_mis_idcharge)))
	BEGIN
		-- Contrôle de l'absence de mission liée à la charge
		IF ((@v_mis_idcharge IS NULL) OR (@v_mis_idcharge IS NOT NULL AND NOT EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE WHERE MIS_IDCHARGE = @v_mis_idcharge)))
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM LEGENDE WHERE LEG_ID = @v_mis_idlegende AND LEG_CATEGORIE = @CATE_MISSION)
				SELECT @v_mis_idlegende = @LEGE_MISSION
			INSERT INTO MISSION (MIS_IDDEMANDE, MIS_IDETAT, MIS_PRIORITE, MIS_DATECREATION, MIS_DATEECHEANCE,
				MIS_IDCHARGE, MIS_TYPEMISSION, MIS_IDAGV, MIS_LEGENDE, MIS_DECHARGE, MIS_TYPE_AGV, MIS_TYPE_OUTIL)
				VALUES (@v_mis_demande, @ETAT_ENATTENTE, @v_mis_priorite, GETDATE(), @v_mis_dateecheance, @v_mis_idcharge,
				@TYPE_NONDEFINI, CASE @v_mis_idagv WHEN 0 THEN NULL ELSE @v_mis_idagv END, @v_mis_idlegende, @v_mis_decharge, @v_mis_idtypeagv, @v_mis_idtypeoutil)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				SELECT @v_mis_idmission = SCOPE_IDENTITY()
				-- Insertion des critères missions non associés à un champ
				INSERT INTO CRITERE_MISSION (CRM_IDCRITERE, CRM_IDMISSION)
					SELECT CRI_IDCRITERE, @v_mis_idmission FROM CRITERE WHERE CRI_FAMILLE = @CRIT_MISSION AND CRI_CHAMP IS NULL
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = @CODE_OK
				ELSE
					SELECT @v_retour = @CODE_KO_SQL
			END
			ELSE
				SELECT @v_retour = @CODE_KO_SQL
		END
		ELSE
			SELECT @v_retour = @CODE_KO_CHARGE
	END
	ELSE
		SELECT @v_retour = @CODE_KO_INCONNU
	IF @v_retour <> @CODE_OK
	BEGIN
		SELECT @v_mis_idmission = 0
		IF @v_local = 1
			ROLLBACK TRAN @v_transaction
	END
	ELSE IF @v_local = 1
		COMMIT TRAN @v_transaction
	RETURN @v_retour



