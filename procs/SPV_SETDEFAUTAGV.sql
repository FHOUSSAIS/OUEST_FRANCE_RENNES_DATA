SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_SETDEFAUTAGV
-- Paramètre d'entrée	: @v_iag_idagv : Identifiant de l'AGV
--						  @v_sens : Sens
--						  @v_dag_iddefaut : Identifiant du défaut
-- Paramètre de sortie	:
-- Descriptif		: Gestion des défauts AGV
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_SETDEFAUTAGV]
	@v_iag_idagv tinyint,
	@v_sens bit,
	@v_dag_iddefaut varchar(80)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

	IF @v_dag_iddefaut = '' AND @v_sens = 0
		DELETE DEFAUT WHERE DEF_ID = @v_iag_idagv AND DEF_TYPE = 1
	ELSE
    BEGIN
		IF @v_sens = 1 AND NOT EXISTS (SELECT 1 FROM DEFAUT WHERE DEF_ID = @v_iag_idagv AND DEF_DEFAUT = @v_dag_iddefaut AND DEF_TYPE = 1)
			INSERT INTO DEFAUT (DEF_ID, DEF_DEFAUT, DEF_TYPE, DEF_DATE) VALUES (@v_iag_idagv, @v_dag_iddefaut, 1, GETDATE())
		ELSE IF @v_sens = 0
			DELETE DEFAUT WHERE DEF_ID = @v_iag_idagv AND DEF_DEFAUT = @v_dag_iddefaut AND DEF_TYPE = 1
    END

