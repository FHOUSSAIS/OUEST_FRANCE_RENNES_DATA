SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_CREATEEVENEMENTENERGIE]
	@v_iag_idagv tinyint,
	@v_tae_idtypeevenement tinyint = NULL
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
	@v_retour int,
	@v_tae_idtype tinyint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_EXISTANT tinyint,
	@CODE_KO_PARAM tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ATTENTE tinyint,
	@ETAT_TERMINE tinyint

-- Déclaration des constantes de type d'objet énergie
DECLARE
	@TYPE_CHANGEMENT_BATTERIE_MANU int,
	@TYPE_RECHARGE_BATTERIE_AUTO_NAVETTE int,
	@TYPE_RECHARGE_BATTERIE_AUTO_AUTONOME int,
	@TYPE_RECHARGE_BATTERIE int

-- Déclaration des constantes de type d'événement d'énergie
DECLARE
	@TYPE_CHANGEMENT_BATTERIE int,
	@TYPE_ENTREE_CHARGE_MANU int,
	@TYPE_ENTREE_CHARGE_AUTO int

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_EXISTANT = 3
	SET @CODE_KO_PARAM = 8
	SET @CODE_KO_SQL = 13
	SET @ETAT_ATTENTE = 1
	SET @ETAT_TERMINE = 3
	SET @TYPE_CHANGEMENT_BATTERIE_MANU = 1
	SET @TYPE_RECHARGE_BATTERIE_AUTO_NAVETTE = 2
	SET @TYPE_RECHARGE_BATTERIE_AUTO_AUTONOME = 3
	SET @TYPE_RECHARGE_BATTERIE = 4
	SET @TYPE_CHANGEMENT_BATTERIE = 1
	SET @TYPE_ENTREE_CHARGE_MANU = 2
	SET @TYPE_ENTREE_CHARGE_AUTO = 4

-- Initialisation des variables
	SET @v_transaction = 'CREATEEVENEMENTENERGIE'
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Vérification des conditions de création de l'événement
	IF NOT EXISTS (SELECT 1 FROM EVT_ENERGIE_EN_COURS WHERE EEC_AGV = @v_iag_idagv AND EEC_ETAT <> @ETAT_TERMINE)
		AND EXISTS (SELECT 1 FROM INFO_AGV WHERE IAG_ID = @v_iag_idagv AND IAG_ENCHARGE = 0)
	BEGIN
		-- Recherche du type d'événement énergie pour l'AGV concerné
		SELECT TOP 1 @v_tae_idtype = CASE COE_TYPE WHEN @TYPE_RECHARGE_BATTERIE THEN ISNULL(@v_tae_idtypeevenement, @TYPE_ENTREE_CHARGE_AUTO) ELSE @TYPE_CHANGEMENT_BATTERIE END
			FROM CONFIG_RSV_ENERGIE, CONFIG_OBJ_ENERGIE
			WHERE CRE_IDAGV = @v_iag_idagv AND CRE_IDOBJ = COE_ID
			AND ((@v_tae_idtypeevenement IS NULL) OR (@v_tae_idtypeevenement = @TYPE_CHANGEMENT_BATTERIE AND COE_TYPE IN (@TYPE_CHANGEMENT_BATTERIE_MANU, @TYPE_RECHARGE_BATTERIE_AUTO_NAVETTE, @TYPE_RECHARGE_BATTERIE_AUTO_AUTONOME))
			OR (@v_tae_idtypeevenement IN (@TYPE_ENTREE_CHARGE_MANU, @TYPE_ENTREE_CHARGE_AUTO) AND COE_TYPE = @TYPE_RECHARGE_BATTERIE))
		IF @v_tae_idtype IS NOT NULL
		BEGIN
			INSERT INTO EVT_ENERGIE_EN_COURS (EEC_DATE, EEC_ETAT, EEC_AGV, EEC_TYPEACT)
				VALUES (GETDATE(), @ETAT_ATTENTE, @v_iag_idagv, @v_tae_idtype)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE INFO_AGV SET IAG_DECHARGE = 1 WHERE IAG_ID = @v_iag_idagv AND IAG_DECHARGE = 0
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = @CODE_OK
				ELSE
					SET @v_retour = @CODE_KO_SQL
			END
			ELSE
				SET @v_retour = @CODE_KO_SQL
		END
		ELSE
			SET @v_retour = @CODE_KO_PARAM
	END
	ELSE
		SET @v_retour = @CODE_KO_EXISTANT
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour


