SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procédure		: IHM_COLORIAGE
-- Paramètre d'entrée	: @v_vue_id : Identifiant
--			  @v_uti_id : Utilisateur
-- Paramètre de sortie	: @v_sql : SQL
-- Descriptif		: Utilisation des règles de coloriage
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Version/ révision	: 1.00
-- Date			: 06/10/2004
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_COLORIAGE]
	@v_vue_id int,
	@v_uti_id varchar(16),
	@v_sql varchar(8000) out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_clr_id int,
	@v_clr_couleur int,
	@v_clr_sql varchar(7000)

	SELECT @v_sql = ''
	IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_COLORIAGE_UTILISATEUR, COLORIAGE WHERE ALU_UTILISATEUR = @v_uti_id
		AND CLR_ID = ALU_COLORIAGE AND CLR_TABLEAU = @v_vue_id)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_COLORIAGE_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE
			WHERE ALG_GROUPE = AUG_GROUPE AND AUG_UTILISATEUR = @v_uti_id)
			DECLARE c_coloriage CURSOR LOCAL FOR SELECT CLR_ID, CLR_COULEUR, CLR_SQL FROM COLORIAGE WHERE CLR_TABLEAU = @v_vue_id AND CLR_SQL IS NOT NULL
		ELSE
			DECLARE c_coloriage CURSOR LOCAL FOR SELECT CLR_ID, MIN(ALG_COULEUR), CLR_SQL FROM COLORIAGE, ASSOCIATION_COLORIAGE_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE
				WHERE CLR_TABLEAU = @v_vue_id AND ALG_COLORIAGE = CLR_ID AND ALG_GROUPE = AUG_GROUPE
				AND AUG_UTILISATEUR = @v_uti_id AND CLR_SQL IS NOT NULL GROUP BY CLR_ID, CLR_SQL
	END
	ELSE
		DECLARE c_coloriage CURSOR LOCAL FOR SELECT CLR_ID, ALU_COULEUR, CLR_SQL FROM ASSOCIATION_COLORIAGE_UTILISATEUR, COLORIAGE
			WHERE CLR_TABLEAU = @v_vue_id AND CLR_ID = ALU_COLORIAGE AND ALU_UTILISATEUR = @v_uti_id AND CLR_SQL IS NOT NULL
	OPEN c_coloriage
	FETCH NEXT FROM c_coloriage INTO @v_clr_id, @v_clr_couleur, @v_clr_sql
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @v_sql <> ''
			SELECT @v_sql = @v_sql + ', '
		SELECT @v_sql = @v_sql + 'CASE WHEN ' + @v_clr_sql + ' THEN ' + CONVERT(VARCHAR, @v_clr_couleur) + ' ELSE NULL END COLORIAGE' + CONVERT(VARCHAR, @v_clr_id)
		FETCH NEXT FROM c_coloriage INTO @v_clr_id, @v_clr_couleur, @v_clr_sql
	END
	CLOSE c_coloriage
	DEALLOCATE c_coloriage	
	RETURN 0


