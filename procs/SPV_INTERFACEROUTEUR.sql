SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_INTERFACEROUTEUR
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_abo_id : Identifiant abonne
--			  @v_mes_id : Identifiant message
--			  @v_iri_id : Identifiant interface routeur
--			  @v_iri_capacite : Capacité
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion de l'interface routeur
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_INTERFACEROUTEUR]
	@v_action smallint,
	@v_abo_id int, 
	@v_mes_id int,
	@v_iri_id int, 
	@v_iri_capacite smallint,
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int
	
-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Initialisation des variables
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	BEGIN TRAN
	SET @v_retour = 113
	IF @v_action = 0
	BEGIN
		INSERT INTO ABONNEMENT (ABN_ABONNE, ABN_MESSAGE, ABN_TIMEOUT) VALUES (@v_abo_id, @v_mes_id, 30)
		SET @v_error = @@ERROR
	END
	ELSE IF @v_action = 1
	BEGIN
		UPDATE INTERFACE_ROUTEUR_IHM SET IRI_CAPACITE = @v_iri_capacite WHERE IRI_ID = @v_iri_id
		SET @v_error = @@ERROR
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE ABONNEMENT WHERE ABN_ABONNE = @v_abo_id AND ABN_MESSAGE = @v_mes_id
		SET @v_error = @@ERROR
	END
	ELSE IF @v_action = 3
	BEGIN
		DELETE ABONNEMENT WHERE ABN_ABONNE = @v_abo_id
		SET @v_error = @@ERROR
	END
	ELSE IF @v_action = 4
	BEGIN
		INSERT INTO ABONNEMENT (ABN_ABONNE, ABN_MESSAGE, ABN_TIMEOUT) SELECT @v_abo_id, ATM_MESSAGE, 30 FROM ASSOCIATION_TYPE_INTERFACE_MESSAGE WHERE ATM_TYPE_INTERFACE = 4
			AND NOT EXISTS (SELECT 1 FROM ABONNEMENT WHERE ABN_ABONNE = @v_abo_id AND ABN_MESSAGE = ATM_MESSAGE)
		SET @v_error = @@ERROR
	END
	IF @v_error = 0
		SET @v_retour = 0
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

